class Tag
  include ActiveModel::Model

  ACCEPTED_MANIFEST_FORMATS = %w[
    application/vnd.oci.image.index.v1+json
    application/vnd.oci.image.manifest.v1+json
    application/vnd.docker.distribution.manifest.list.v2+json
    application/vnd.docker.distribution.manifest.v2+json
    application/vnd.docker.distribution.manifest.v1+json
  ]

  attr_accessor :name, :artifact, :push_time, :pull_time, :content_digest,
                :project_name, :repository_name

  def display_type
    artifact&.display_type
  end

  def type_icon
    artifact&.type_icon
  end

  def self.list(project_name:, repository_name:, page: 1, page_size: Rails.configuration.x.page_size)
    artifacts = Artifact.list(project_name: project_name, repository_name: repository_name, page: page, page_size: page_size)

    tags = []
    artifacts.each do |artifact|
      artifact.tags.each do |tag_name|
        tags << new(
          name: tag_name,
          artifact: artifact,
          push_time: artifact.push_time,
          pull_time: artifact.pull_time,
          content_digest: artifact.digest,
          project_name: project_name,
          repository_name: repository_name
        )
      end
    end

    Collection.new(entries: tags, more: artifacts.more?, total: artifacts.total, page: artifacts.page)
  end

  def self.find(project_name:, repository_name:, name:)
    response = HarborClient.api.get(
      "projects/#{project_name}/repositories/#{CGI.escape(repository_name)}/artifacts/#{name}",
      with_tag: true,
      with_label: false,
      with_scan_overview: false,
      with_sbom_overview: false,
      with_immutable_status: false,
      with_accessory: false
    )

    artifact = Artifact.from_api(response.body, project_name, repository_name)

    new(
      name: name,
      artifact: artifact,
      push_time: artifact.push_time,
      pull_time: artifact.pull_time,
      content_digest: artifact.digest,
      project_name: project_name,
      repository_name: repository_name
    )
  end

  def manifests
    @manifests ||= fetch_manifests.sort_by(&:architecture)
  end

  private

  def fetch_manifests
    references = artifact.references || []

    if references.any?
      image_refs = references.reject do |ref|
        ref.dig("platform", "architecture") == "unknown" ||
        ref.dig("platform", "os") == "unknown"
      end

      image_refs.map { |ref| fetch_manifest_detail(ref.fetch("child_digest")) }
    else
      [ fetch_manifest_detail(content_digest) ]
    end
  end

  def fetch_manifest_detail(digest)
    full_repo = "#{project_name}/#{repository_name}"

    response = HarborClient.oci.get("#{full_repo}/manifests/#{digest}") do |req|
      req.headers["Accept"] = ACCEPTED_MANIFEST_FORMATS.join(", ")
    end

    manifest = response.body

    config_digest = manifest.dig("config", "digest")
    blob = {}
    if config_digest
      blob_response = HarborClient.oci.get("#{full_repo}/blobs/#{config_digest}")
      blob = blob_response.body
      blob = JSON.parse(blob) if blob.instance_of?(String)
    end

    layers = Array.wrap(manifest["layers"] || manifest["fsLayers"]).each_with_index.map do |layer, index|
      Layer.new(
        index:  index + 1,
        digest: layer["digest"] || layer["blobSum"],
        size:   layer["size"]
      )
    end

    scan_overview, sbom_overview, vulnerabilities = fetch_scan_data(digest)

    Manifest.new(
      architecture:   [ blob.dig("architecture"), blob.dig("variant") ].compact.join("-"),
      content_digest: config_digest,
      created:        (Time.parse(blob.dig("created")) rescue nil),
      env:            blob.dig("config", "Env") || [],
      history:        blob.fetch("history", []).map { |e| HistoryEntry.new(e) },
      labels:         blob.dig("config", "Labels") || {},
      layers:         layers,
      size:           layers.sum(&:size),
      os:             blob.dig("os"),
      scan_overview:  scan_overview,
      sbom_overview:  sbom_overview,
      vulnerabilities: vulnerabilities
    )
  end

  def fetch_scan_data(digest)
    artifact_resp = HarborClient.api.get(
      "projects/#{project_name}/repositories/#{CGI.escape(repository_name)}/artifacts/#{digest}",
      with_tag: false,
      with_label: false,
      with_scan_overview: true,
      with_sbom_overview: true,
      with_immutable_status: false,
      with_accessory: false
    )
    scan_overview = artifact_resp.body["scan_overview"]
    sbom_overview = artifact_resp.body["sbom_overview"]

    vulnerabilities = nil
    if scan_overview.present?
      vulnerabilities = fetch_vulnerabilities(digest)
    end

    [ scan_overview, sbom_overview, vulnerabilities ]
  rescue Faraday::ResourceNotFound, Faraday::ClientError
    [ nil, nil, nil ]
  end

  def fetch_vulnerabilities(digest)
    response = HarborClient.api.get(
      "projects/#{project_name}/repositories/#{CGI.escape(repository_name)}/artifacts/#{digest}/additions/vulnerabilities"
    ) do |req|
      req.headers["X-Accept-Vulnerabilities"] = "application/vnd.security.vulnerability.report; version=1.1"
    end
    report_key = "application/vnd.security.vulnerability.report; version=1.1"
    report = response.body[report_key]
    report&.dig("vulnerabilities")
  rescue Faraday::ResourceNotFound, Faraday::ClientError
    nil
  end
end
