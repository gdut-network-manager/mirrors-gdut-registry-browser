class ProjectsController < ApplicationController
  def index
    @projects = Project.list(page: params[:page]&.to_i || 1)
    @converter_config = {
      domainMap: Project.registry_domain_map,
      mirrorMap: parse_mirror_map,
      registryUrl: Rails.configuration.x.public_registry_url&.sub(/^https?:\/\//, ""),
      helpUrl: "https://mirrors.gdut.edu.cn/help/docs/mirrors/docker-help"
    }
  end

  private

  def parse_mirror_map
    map_string = Rails.configuration.x.domain_mirror_map
    return {} unless map_string.present?

    map_string.split(",").each_with_object({}) do |entry, hash|
      key, value = entry.split(":")
      hash[key.strip] = value.strip if key && value
    end
  end
end
