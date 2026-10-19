class Repository
  include ActiveModel::Model

  attr_accessor :name, :project_name, :artifact_count, :pull_count, :description, :update_time

  # Harbor 服务端仅支持对 repository 表的数据库列排序。
  # artifact_count 是 API 返回时现算的字段, 传给 sort 会被 Harbor 静默忽略并回落默认序,
  # 因此该列排序必须客户端模拟: 拉全量后内存排序 + 本地切片分页。
  SERVER_SORTABLE = %w[name pull_count].freeze
  CLIENT_SORT_KEYS = %w[artifact_count update_time].freeze

  def self.list(project_name:, page: 1, page_size: Rails.configuration.x.page_size, query: nil, sort: nil)
    sort_field = sort.to_s.sub(/\A-/, "")
    desc = sort.to_s.start_with?("-")
    client_side = CLIENT_SORT_KEYS.include?(sort_field)

    if client_side
      list_client_sorted(
        project_name: project_name,
        page: page, page_size: page_size,
        query: query, sort_field: sort_field, desc: desc
      )
    else
      list_server_sorted(
        project_name: project_name,
        page: page, page_size: page_size,
        query: query, sort: sort
      )
    end
  end

  def self.server_sortable?(sort)
    field = sort.to_s.sub(/\A-/, "")
    SERVER_SORTABLE.include?(field)
  end

  def self.list_server_sorted(project_name:, page:, page_size:, query:, sort:)
    params = { page: page, page_size: page_size }
    params[:q] = "name=~#{query}" if query.present?
    params[:sort] = sort if sort.present?

    response = HarborClient.api.get(
      "projects/#{project_name}/repositories",
      params
    )

    entries = build_entries(response.body, project_name)
    total = response.headers["x-total-count"].to_i

    Collection.new(entries: entries, more: page * page_size < total, total: total, page: page)
  end

  # Harbor page_size 上限 100, 分页拉全量后在内存中排序再切片
  def self.list_client_sorted(project_name:, page:, page_size:, query:, sort_field:, desc:)
    all_entries = []
    page_num = 1
    total = nil

    loop do
      params = { page: page_num, page_size: 100 }
      params[:q] = "name=~#{query}" if query.present?
      params[:sort] = "name" # 固定服务端序保证分页稳定, 排序在内存完成

      response = HarborClient.api.get(
        "projects/#{project_name}/repositories",
        params
      )
      total = response.headers["x-total-count"].to_i
      all_entries.concat(build_entries(response.body, project_name))

      break if all_entries.size >= total || response.body.empty?
      page_num += 1
    end

    all_entries.sort_by! do |r|
      [r.public_send(sort_field).to_i, r.name.to_s]
    end
    all_entries.reverse! if desc

    offset = (page - 1) * page_size
    Collection.new(
      entries: all_entries[offset, page_size] || [],
      more: offset + page_size < all_entries.size,
      total: all_entries.size,
      page: page
    )
  end

  def self.build_entries(body, project_name)
    body.map do |r|
      new(
        name: r["name"],
        project_name: project_name,
        artifact_count: r["artifact_count"],
        pull_count: r["pull_count"],
        description: r["description"],
        update_time: r["update_time"]
      )
    end
  end

  def self.find(project_name:, name:)
    response = HarborClient.api.get("projects/#{project_name}/repositories/#{CGI.escape(name)}")

    new(
      name: response.body["name"],
      project_name: project_name,
      artifact_count: response.body["artifact_count"],
      pull_count: response.body["pull_count"],
      description: response.body["description"]
    )
  end

  def relative_name
    return name unless project_name.present? && name.start_with?("#{project_name}/")
    name.sub("#{project_name}/", "")
  end

  def has_description?
    description.present? && description.strip != ""
  end
end
