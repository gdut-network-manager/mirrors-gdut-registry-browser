class ProjectsController < ApplicationController
  def index
    @projects = Project.list(page: params[:page]&.to_i || 1)
  end
end
