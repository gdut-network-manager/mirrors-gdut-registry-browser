class RepositoriesController < ApplicationController
  helper_method :configs

  def index
    @project = Project.find(params[:project_name])
    @query = params[:q].to_s.strip
    @repositories = Repository.list(
      project_name: params[:project_name],
      page: params[:page]&.to_i || 1,
      query: @query.presence
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
