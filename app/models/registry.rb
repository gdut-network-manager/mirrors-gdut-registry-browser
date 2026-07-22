class Registry
  include ActiveModel::Model

  attr_accessor :id, :name, :url, :type, :status

  def display_name
    case type
    when "docker-hub"     then "Docker Hub"
    when "github"         then "GitHub Container Registry"
    when "quay"           then "Quay.io"
    when "harbor"         then "Harbor"
    when "google-gcr"     then "Google Container Registry"
    when "aws-ecr"        then "AWS ECR"
    when "azure-acr"      then "Azure ACR"
    when "docker-registry" then "Docker Registry"
    when "jfrog-artifactory" then "JFrog Artifactory"
    else type&.humanize || name
    end
  end
end
