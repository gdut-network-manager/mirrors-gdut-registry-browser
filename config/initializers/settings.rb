require "config"

Rails.application.config.tap do |config|
  # Harbor connection
  config.x.harbor_url          = Config.get(name: "HARBOR_URL", default: "http://localhost:8080")
  config.x.harbor_username     = Config.get(name: "HARBOR_USERNAME", secret: true)
  config.x.harbor_password     = Config.get(name: "HARBOR_PASSWORD", secret: true)

  # Public registry URL for docker pull commands
  config.x.public_registry_url = Config.get(name: "PUBLIC_REGISTRY_URL")

  # Domain mirror map: project_name -> subdomain (e.g. "ghcr.io:ghcr,quay.io:quay")
  config.x.domain_mirror_map   = Config.get(name: "DOMAIN_MIRROR_MAP")

  # Pagination
  config.x.page_size           = Config.get(name: "PAGE_SIZE", default: 20).to_i

  # SSL
  config.x.no_ssl_verification = Config.get(name: "NO_SSL_VERIFICATION").in? %w[1 true yes]
  config.x.ca_file             = Config.get(name: "CA_FILE")

  # Faraday logger options
  config.x.registry_log_options = {
    log_level: Config.get(name: "REGISTRY_LOG_LEVEL", default: "info").to_sym,
    headers: (Config.get(name: "REGISTRY_LOG_HEADERS", default: "false").in? %w[1 true yes])
  }
end
