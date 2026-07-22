class Project
  include ActiveModel::Model

  attr_accessor :name, :registry_id, :repo_count, :upstream_registry, :quota_used, :quota_hard, :creation_time

  def self.list(page: 1, page_size: Rails.configuration.x.page_size)
    registry_map = fetch_registry_map
    quota_map = fetch_quota_map

    all_projects = fetch_all_projects
    proxy_cache_projects = all_projects.select { |p| !p["registry_id"].nil? && p["registry_id"] > 0 }

    start_idx = (page - 1) * page_size
    page_projects = proxy_cache_projects[start_idx, page_size] || []

    entries = page_projects.map do |p|
      quota = quota_map[p["name"]] || {}
      new(
        name: p["name"],
        registry_id: p["registry_id"],
        repo_count: p["repo_count"],
        upstream_registry: registry_map[p["registry_id"]],
        quota_used: quota[:used],
        quota_hard: quota[:hard],
        creation_time: p["creation_time"]
      )
    end

    more = start_idx + page_size < proxy_cache_projects.size
    total_pages = (proxy_cache_projects.size.to_f / page_size).ceil

    Collection.new(entries: entries, more: more, total: proxy_cache_projects.size, page: page)
  end

  def self.find(name)
    response = HarborClient.api.get("projects/#{name}")

    project = new(
      name: response.body["name"],
      registry_id: response.body["registry_id"],
      repo_count: response.body["repo_count"]
    )

    project.upstream_registry = fetch_registry_for(project) if project.registry_id.present?

    summary = HarborClient.api.get("projects/#{name}/summary").body
    project.quota_used = summary.dig("quota", "used", "storage")
    project.quota_hard = summary.dig("quota", "hard", "storage")

    project
  end

  def quota_percentage
    return 0 if quota_hard.nil? || quota_hard.zero?
    (quota_used.to_f / quota_hard * 100).round(1)
  end

  def self.fetch_registry_map
    {}.tap do |map|
      begin
        HarborClient.api.get("registries").body.each do |r|
          map[r["id"]] = Registry.new(id: r["id"], name: r["name"], url: r["url"], type: r["type"], status: r["status"])
        end
      rescue Faraday::Error
      end
    end
  end

  def self.fetch_quota_map
    {}.tap do |map|
      begin
        HarborClient.api.get("quotas", page: 1, page_size: 100).body.each do |q|
          name = q.dig("ref", "name")
          next unless name
          map[name] = {
            used: q.dig("used", "storage"),
            hard: q.dig("hard", "storage")
          }
        end
      rescue Faraday::Error
      end
    end
  end

  def self.fetch_registry_for(project)
    response = HarborClient.api.get("projects/#{project.name}/summary")
    registry_data = response.body["registry"]
    return nil unless registry_data

    Registry.new(id: registry_data["id"], name: registry_data["name"], url: registry_data["url"], type: registry_data["type"], status: registry_data["status"])
  end

  def self.fetch_all_projects
    all = []
    page = 1
    loop do
      response = HarborClient.api.get("projects", page: page, page_size: 100, with_detail: true)
      all.concat(response.body)
      total = response.headers["x-total-count"].to_i
      break if all.size >= total || response.body.empty?
      page += 1
    end
    all
  end

  private_class_method :fetch_registry_map, :fetch_quota_map, :fetch_registry_for, :fetch_all_projects
end
