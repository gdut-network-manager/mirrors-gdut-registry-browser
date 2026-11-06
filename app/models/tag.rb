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
                :project_name, :repository_name, :size, :scan_overview

  def display_type
    artifact&.display_type
  end

  def type_icon
    artifact&.type_icon
  end

  def reference
    name.presence || content_digest
  end

  def display_name
    return name if name.present?
    d = content_digest.to_s
    d.length > 19 ? d[0, 19] + "\u2026" : d
  end

  # Harbor 服务端可排序的制品列(实测: digest / size / push_time / pull_time)
  SERVER_SORTABLE = %w[digest size push_time pull_time].freeze
  # 需客户端模拟: 标签名来自 tag 关联表, 漏洞总数由 scan_overview 现算
  CLIENT_SORT_KEYS = %w[tag vuln].freeze
  SORT_WHITELIST = (SERVER_SORTABLE + CLIENT_SORT_KEYS).flat_map { |k| [ k, "-#{k}" ] }.freeze
  DEFAULT_SORT = "-push_time"

  def self.list(project_name:, repository_name:, page: 1, page_size: Rails.configuration.x.page_size, sort: DEFAULT_SORT)
    sort = DEFAULT_SORT unless SORT_WHITELIST.include?(sort.to_s)
    sort_field = sort.to_s.sub(/\A-/, "")
    desc = sort.to_s.start_with?("-")

    if CLIENT_SORT_KEYS.include?(sort_field)
      list_client_sorted(
        project_name: project_name, repository_name: repository_name,
        page: page, page_size: page_size,
        sort_field: sort_field, desc: desc
      )
    else
      list_server_sorted(
        project_name: project_name, repository_name: repository_name,
        page: page, page_size: page_size, sort: sort
      )
    end
  end

  def self.list_server_sorted(project_name:, repository_name:, page:, page_size:, sort:)
    artifacts = Artifact.list(
      project_name: project_name, repository_name: repository_name,
      page: page, page_size: page_size, sort: sort
    )

    Collection.new(
      entries: build_entries(artifacts, project_name, repository_name),
      more: artifacts.more?, total: artifacts.total, page: artifacts.page
    )
  end

  # 分页拉全量制品后在内存排序再切片; 未扫描的制品(漏洞数未知)始终排在末尾
  def self.list_client_sorted(project_name:, repository_name:, page:, page_size:, sort_field:, desc:)
    artifacts = Artifact.list_all(project_name: project_name, repository_name: repository_name)
    entries = build_entries(artifacts, project_name, repository_name)

    known, unknown = entries.partition { |tag| !sort_value(tag, sort_field).nil? }
    known.sort_by! { |tag| [ sort_value(tag, sort_field), tag.content_digest.to_s ] }
    known.reverse! if desc
    sorted = known + unknown

    offset = (page - 1) * page_size
    Collection.new(
      entries: sorted[offset, page_size] || [],
      more: offset + page_size < sorted.size,
      total: sorted.size,
      page: page
    )
  end

  def self.sort_value(tag, field)
    case field
    when "tag" then tag.name.presence&.downcase
    when "vuln" then tag.artifact&.scan_summary&.dig(:total)
    end
  end

  def self.build_entries(artifacts, project_name, repository_name)
    tags = []
    artifacts.each do |artifact|
      base = {
        artifact: artifact,
        push_time: artifact.push_time,
        pull_time: artifact.pull_time,
        content_digest: artifact.digest,
        project_name: project_name,
        repository_name: repository_name,
        size: artifact.size,
        scan_overview: artifact.scan_overview
      }
      if artifact.tags.any?
        artifact.tags.each do |tag_name|
          tags << new(**base, name: tag_name)
        end
      else
        tags << new(**base, name: nil)
      end
    end
    tags
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

    actual_name = artifact.tags.include?(name) ? name : nil

    new(
      name: actual_name,
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

  # 按需拉取漏洞列表 (由 controller 调用)
  def self.fetch_vulnerabilities(project_name:, repository_name:, digest:)
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

    scan_overview, sbom_overview = fetch_scan_overview(digest)

    Manifest.new(
      architecture:    [ blob.dig("architecture"), blob.dig("variant") ].compact.join("-"),
      content_digest:  config_digest,
      created:         (Time.parse(blob.dig("created")) rescue nil),
      env:             blob.dig("config", "Env") || [],
      history:         blob.fetch("history", []).map { |e| HistoryEntry.new(e) },
      labels:          blob.dig("config", "Labels") || {},
      layers:          layers,
      size:            layers.sum(&:size),
      os:              blob.dig("os"),
      scan_overview:   scan_overview,
      sbom_overview:   sbom_overview,
      artifact_digest: digest
    )
  end

  # 只拉取扫描摘要, 不拉取完整漏洞报告
  def fetch_scan_overview(digest)
    artifact_resp = HarborClient.api.get(
      "projects/#{project_name}/repositories/#{CGI.escape(repository_name)}/artifacts/#{digest}",
      with_tag: false,
      with_label: false,
      with_scan_overview: true,
      with_sbom_overview: true,
      with_immutable_status: false,
      with_accessory: false
    )
    [ artifact_resp.body["scan_overview"], artifact_resp.body["sbom_overview"] ]
  rescue Faraday::ResourceNotFound, Faraday::ClientError
    [ nil, nil ]
  end
end
