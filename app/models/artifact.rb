class Artifact
  include ActiveModel::Model

  attr_accessor :digest, :size, :type, :media_type, :manifest_media_type,
                :architecture, :os, :references, :tags, :push_time, :pull_time,
                :repository_name, :project_name, :scan_overview

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

  # Harbor 制品接口的 sort 参数只对 artifact 表的真实列生效
  # (已实测: digest / size / push_time / pull_time 可用, 默认序等价于 -push_time)
  SERVER_SORTABLE = %w[digest size push_time pull_time].freeze

  def self.list(project_name:, repository_name:, page: 1, page_size: Rails.configuration.x.page_size, sort: nil)
    params = {
      page: page,
      page_size: page_size,
      with_tag: true,
      with_label: false,
      with_scan_overview: true,
      with_sbom_overview: false,
      with_immutable_status: false,
      with_accessory: false
    }
    params[:sort] = sort if SERVER_SORTABLE.include?(sort.to_s.sub(/\A-/, ""))

    response = HarborClient.api.get(
      "projects/#{project_name}/repositories/#{CGI.escape(repository_name)}/artifacts",
      params
    )

    entries = response.body.map do |a|
      from_api(a, project_name, repository_name)
    end

    total = response.headers["x-total-count"].to_i
    more = page * page_size < total

    Collection.new(entries: entries, more: more, total: total, page: page)
  end

  # 拉取全部制品(客户端排序用)。page_size 上限 100, 固定服务端序保证分页稳定。
  def self.list_all(project_name:, repository_name:)
    all = []
    page = 1
    total = nil

    loop do
      collection = list(
        project_name: project_name,
        repository_name: repository_name,
        page: page,
        page_size: 100,
        sort: "digest"
      )
      total = collection.total
      all.concat(collection.entries)

      break if all.size >= total || collection.entries.empty?
      page += 1
    end

    all
  end

  VULN_SEVERITY_ORDER = { "Critical" => 0, "High" => 1, "Medium" => 2, "Low" => 3, "Unknown" => 4 }.freeze

  def scan_summary
    overview = scan_overview.to_h.values.first
    return nil if overview.nil?
    details = overview.dig("summary", "summary") || {}
    sorted = details.sort_by { |sev, _| VULN_SEVERITY_ORDER.fetch(sev, 99) }.to_h
    {
      status: overview["scan_status"],
      severity: overview["severity"],
      total: sorted.values.sum,
      details: sorted
    }
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
      scan_overview: data["scan_overview"],
      repository_name: repository_name,
      project_name: project_name
    )
  end
end
