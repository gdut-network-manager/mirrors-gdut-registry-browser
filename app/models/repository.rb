class Repository
  include ActiveModel::Model

  attr_accessor :name, :project_name, :artifact_count, :pull_count, :description

  def self.list(project_name:, page: 1, page_size: Rails.configuration.x.page_size, query: nil)
    params = { page: page, page_size: page_size }
    params[:q] = "name=~#{query}" if query.present?

    response = HarborClient.api.get(
      "projects/#{project_name}/repositories",
      params
    )

    entries = response.body.map do |r|
      new(
        name: r["name"],
        project_name: project_name,
        artifact_count: r["artifact_count"],
        pull_count: r["pull_count"],
        description: r["description"]
      )
    end

    total = response.headers["x-total-count"].to_i
    more = page * page_size < total

    Collection.new(entries: entries, more: more, total: total, page: page)
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
