class Artifact
  include ActiveModel::Model

  attr_accessor :digest, :size, :type, :media_type, :manifest_media_type,
                :architecture, :os, :references, :tags, :push_time, :pull_time,
                :repository_name, :project_name

  def display_type
    case type
    when "IMAGE"
      "容器镜像"
    when "CHART"
      "Helm Chart"
    when "CNAB"
      "CNAB"
    when "WASM"
      "WASM"
    when "SBOM"
      "SBOM"
    when "CNAI"
      "AI 模型"
    when "OPENPOLICYAGENT"
      "OPA"
    when nil, ""
      if media_type&.include?("helm") || manifest_media_type&.include?("helm")
        "Helm Chart"
      elsif media_type&.include?("wasm") || manifest_media_type&.include?("wasm")
        "WASM"
      else
        "OCI 制品"
      end
    else
      type.humanize
    end
  end

  def type_icon
    case display_type
    when "容器镜像" then "container"
    when "Helm Chart" then "helm"
    when "WASM" then "hexagon"
    when "CNAB" then "package"
    when "SBOM" then "list"
    when "AI 模型" then "hexagon"
    when "OPA" then "shield"
    else "box"
    end
  end

  def self.list(project_name:, repository_name:, page: 1, page_size: Rails.configuration.x.page_size)
    response = HarborClient.api.get(
      "projects/#{project_name}/repositories/#{CGI.escape(repository_name)}/artifacts",
      page: page,
      page_size: page_size,
      with_tag: true,
      with_label: false,
      with_scan_overview: false,
      with_sbom_overview: false,
      with_immutable_status: false,
      with_accessory: false
    )

    entries = response.body.map do |a|
      from_api(a, project_name, repository_name)
    end

    total = response.headers["x-total-count"].to_i
    more = page * page_size < total

    Collection.new(entries: entries, more: more, total: total, page: page)
  end

  def self.from_api(data, project_name, repository_name)
    extra = data["extra_attrs"] || {}

    new(
      digest: data["digest"],
      size: data["size"],
      type: data["type"],
      media_type: data["media_type"],
      manifest_media_type: data["manifest_media_type"],
      architecture: extra["architecture"],
      os: extra["os"],
      references: data["references"] || [],
      tags: (data["tags"] || []).map { |t| t["name"] },
      push_time: data["push_time"],
      pull_time: data["pull_time"],
      repository_name: repository_name,
      project_name: project_name
    )
  end
end
