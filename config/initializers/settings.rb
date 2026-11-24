require "config"

Rails.application.config.tap do |config|
  # Harbor connection
  config.x.harbor_url          = Config.get(name: "HARBOR_URL", default: "http://localhost:8080")
  config.x.harbor_username     = Config.get(name: "HARBOR_USERNAME", secret: true)
  config.x.harbor_password     = Config.get(name: "HARBOR_PASSWORD", secret: true)

  # Harbor 请求超时与重试(秒)。Harbor 偶发卡顿 60s, 短超时 + 重试可快速绕过
  config.x.harbor_timeout      = Config.get(name: "HARBOR_TIMEOUT", default: 10).to_i
  config.x.harbor_open_timeout = Config.get(name: "HARBOR_OPEN_TIMEOUT", default: 5).to_i
  config.x.harbor_max_retries  = Config.get(name: "HARBOR_MAX_RETRIES", default: 2).to_i

  # Harbor 数据缓存时长(秒), 0 表示不缓存
  # LIST: 仓库/制品列表等变化较快的数据; META: 项目、配额、上游仓库等元数据
  config.x.harbor_list_cache_ttl = Config.get(name: "HARBOR_LIST_CACHE_TTL", default: 60).to_i
  config.x.harbor_meta_cache_ttl = Config.get(name: "HARBOR_META_CACHE_TTL", default: 300).to_i

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
