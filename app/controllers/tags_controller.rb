class TagsController < ApplicationController
  before_action :find_tag, only: %i[show]

  def show
  end

  def vulnerabilities
    manifest_id = params[:manifest_id]
    artifact_digest = params[:artifact_digest]

    if artifact_digest.blank?
      render partial: "manifests/sections/vuln_frame", locals: { manifest_id: manifest_id, vulnerabilities: [] }
      return
    end

    vulnerabilities = Tag.fetch_vulnerabilities(
      project_name: params[:project_name],
      repository_name: params[:repo],
      digest: artifact_digest
    ) || []

    render partial: "manifests/sections/vuln_frame", locals: { manifest_id: manifest_id, vulnerabilities: vulnerabilities }
  rescue Faraday::ClientError => e
    message = e.response&.dig(:body, "errors", 0, "message") || "漏洞列表加载失败"
    render html: "<turbo-frame id=\"vuln-frame-#{ERB::Util.html_escape(manifest_id)}\"><div class=\"empty-state\"><p>#{ERB::Util.html_escape(message)}</p></div></turbo-frame>".html_safe
  end

  def sbom
    sbom_digest = params[:sbom_digest]
    manifest_id = params[:manifest_id]

    if sbom_digest.blank?
      render partial: "manifests/sections/sbom_frame", locals: { manifest_id: manifest_id, packages: [] }
      return
    end

    packages = fetch_sbom_packages(sbom_digest)
    render partial: "manifests/sections/sbom_frame", locals: { manifest_id: manifest_id, packages: packages }
  rescue Faraday::ClientError => e
    message = e.response&.dig(:body, "errors", 0, "message") || "SBOM 加载失败"
    render html: "<turbo-frame id=\"sbom-frame-#{ERB::Util.html_escape(manifest_id)}\"><div class=\"empty-state\"><p>#{ERB::Util.html_escape(message)}</p></div></turbo-frame>".html_safe
  end

  private

  def find_tag
    @project = Project.find(params[:project_name])
    @repository = Repository.find(project_name: params[:project_name], name: params[:repo])
    @tag = Tag.find(project_name: params[:project_name], repository_name: params[:repo], name: params[:tag])
  end

  def fetch_sbom_packages(sbom_digest)
    response = HarborClient.api.get(
      "projects/#{params[:project_name]}/repositories/#{CGI.escape(params[:repo])}/artifacts/#{sbom_digest}/additions/sbom"
    )
    body = response.body
    body = JSON.parse(body) if body.is_a?(String)
    body["packages"] || []
  end
end
