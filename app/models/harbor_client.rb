class HarborClient
  # Harbor 偶发整整卡住 60s 才响应(实测约 8% 的请求), 但立即重试通常 0.1s 内就能返回。
  # 因此用较短的读超时 + 对幂等 GET 自动重试, 避免单次卡顿拖垮整个页面(ingress 60s 超时 → 504)。
  class RetryOnTimeout < Faraday::Middleware
    RETRIABLE_ERRORS = [ Faraday::TimeoutError, Faraday::ConnectionFailed ].freeze

    def initialize(app, max_retries: 2)
      super(app)
      @max_retries = max_retries
    end

    def call(env)
      attempts = 0
      begin
        @app.call(env)
      rescue *RETRIABLE_ERRORS => e
        raise unless env.method == :get && attempts < @max_retries
        attempts += 1
        Rails.logger.warn("[HarborClient] #{e.class} on GET #{env.url}, retry #{attempts}/#{@max_retries}")
        retry
      end
    end
  end

  class << self
    def api
      connection("/api/v2.0")
    end

    def oci
      connection("/v2")
    end

    CachedResponse = Struct.new(:body, :total, keyword_init: true)

    # 带缓存的 API GET。只缓存纯数据(body + x-total-count), 不缓存 Faraday 响应对象。
    # 缓存可以减少每个页面的串行请求数, 降低碰上 Harbor 卡顿的概率。
    #
    # 另存一份「最后一次成功」的副本(保留 STALE_TTL): Harbor 重试后仍超时/5xx 时用它兜底,
    # 宁可展示稍旧的数据也不要整页报错。
    STALE_TTL = 24 * 60 * 60

    def cached_get(path, params = {}, expires_in:)
      return wrap(fetch_raw(path, params)) if expires_in.to_i <= 0

      key = [ "harbor", path, params.to_a.sort_by { |k, _| k.to_s } ].flatten.join("|")
      data = Rails.cache.fetch(key, expires_in: expires_in.to_i, race_condition_ttl: 10) do
        fresh = fetch_raw(path, params)
        Rails.cache.write("#{key}|stale", fresh, expires_in: STALE_TTL)
        fresh
      end
      wrap(data)
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed, Faraday::ServerError => e
      stale = key && Rails.cache.read("#{key}|stale")
      raise unless stale
      Rails.logger.warn("[HarborClient] #{e.class} on #{path}, serving stale cache")
      wrap(stale)
    end

    private

    def fetch_raw(path, params)
      response = api.get(path, params)
      { "body" => response.body, "total" => response.headers["x-total-count"] }
    end

    def wrap(data)
      CachedResponse.new(body: data["body"], total: data["total"].to_i)
    end

    public

    def list_cache_ttl
      Rails.configuration.x.harbor_list_cache_ttl
    end

    def meta_cache_ttl
      Rails.configuration.x.harbor_meta_cache_ttl
    end

    private

    def connection(prefix)
      Faraday.new(url: "#{base_url}#{prefix}", ssl: ssl_options) do |f|
        f.use RetryOnTimeout, max_retries: Rails.configuration.x.harbor_max_retries
        if username.present? && password.present?
          f.request :authorization, :basic, username, password
        end
        f.response :follow_redirects, limit: 5
        f.response :json, content_type: /json|prettyjws|sbom\.v\d/
        f.response :logger, Rails.configuration.logger, Rails.configuration.x.registry_log_options
        f.response :raise_error
        f.options.timeout = Rails.configuration.x.harbor_timeout
        f.options.open_timeout = Rails.configuration.x.harbor_open_timeout
        f.adapter Faraday.default_adapter
      end
    end

    def base_url
      Rails.configuration.x.harbor_url
    end

    def username
      Rails.configuration.x.harbor_username
    end

    def password
      Rails.configuration.x.harbor_password
    end

    def ssl_options
      {
        verify:  Rails.configuration.x.no_ssl_verification.!,
        ca_file: Rails.configuration.x.ca_file
      }.compact
    end
  end
end
