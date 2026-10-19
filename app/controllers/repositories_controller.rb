class RepositoriesController < ApplicationController
  helper_method :configs

  SORT_WHITELIST = %w[name -name artifact_count -artifact_count pull_count -pull_count update_time -update_time].freeze

  def index
    @project = Project.find(params[:project_name])
    @query = params[:q].to_s.strip
    @sort = SORT_WHITELIST.include?(params[:sort]) ? params[:sort] : "-pull_count"
    @repositories = Repository.list(
      project_name: params[:project_name],
      page: params[:page]&.to_i || 1,
      query: @query.presence,
      sort: @sort
    )
  end

  def show
    @project = Project.find(params[:project_name])
    @repository = Repository.find(project_name: params[:project_name], name: params[:repo])
    @tags_collection = Tag.list(
      project_name: params[:project_name],
      repository_name: params[:repo],
      page: params[:page]&.to_i || 1
    )
    @tags = @tags_collection.entries
  end

  private

  def configs
    Rails.application.config.x
  end
end
