class HarborClient
  class << self
    def api
      connection("/api/v2.0")
    end

    def oci
      connection("/v2")
    end

    private

    def connection(prefix)
      Faraday.new(url: "#{base_url}#{prefix}", ssl: ssl_options) do |f|
        if username.present? && password.present?
          f.request :authorization, :basic, username, password
        end
        f.response :follow_redirects, limit: 5
        f.response :json, content_type: /json|prettyjws/
        f.response :logger, Rails.configuration.logger, Rails.configuration.x.registry_log_options
        f.response :raise_error
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
