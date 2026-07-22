class TagsController < ApplicationController
  before_action :find_tag

  def show
  end

  private

  def find_tag
    @project = Project.find(params[:project_name])
    @repository = Repository.find(project_name: params[:project_name], name: params[:repo])
    @tag = Tag.find(project_name: params[:project_name], repository_name: params[:repo], name: params[:tag])
  end
end
