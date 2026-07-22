class ApplicationController < ActionController::Base
  rescue_from Faraday::ResourceNotFound, with: :not_found
  rescue_from Faraday::ClientError, with: :client_error
  rescue_from Faraday::ServerError, with: :server_error
  rescue_from Faraday::Error, with: :connection_error

  private

  def not_found
    render file: "#{Rails.root}/public/404.html", layout: false, status: 404
  end

  def client_error(error)
    status = error.response&.dig(:status)
    case status
    when 401
      render "errors/auth_failed", status: 401
    when 403
      render "errors/forbidden", status: 403
    else
      raise error
    end
  end

  def server_error(error)
    render "errors/service_unavailable", status: 502
  end

  def connection_error(error)
    render "errors/service_unavailable", status: 502
  end
end
