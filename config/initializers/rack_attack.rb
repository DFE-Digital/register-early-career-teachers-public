class Rack::Attack
  class Request < ::Rack::Request
    def remote_ip
      # This will always be present because the ActionDispatch::RemoteIp
      # middleware runs long before this middleware. Use #fetch here
      # so that we bail quickly if that middleware goes away or changes
      # the field name. Have preferred this to instantiating a whole
      # ActionDispatch::Request as that's a whole lot of work and this happens
      # on every request.
      #
      # Favour the X-Real-IP header if set by Azure, if not fallback to
      # ActionDispatch#remote_ip which is more reliable than Rack's ip method.
      @remote_ip ||= env.fetch("x-real-ip", nil).presence || env.fetch("action_dispatch.remote_ip").to_s
    end
  end

  PROTECTED_ROUTES = %w[
    /otp-sign-in
    /otp-sign-in/code
    /otp-sign-in/verify
    /sign-in
    /auth
    /healthcheck
  ].freeze

  PUBLIC_API_PATH_PREFIXES = [
    "/api/guidance",
    "/api/docs",
  ].freeze

  def self.protected_path?(request)
    PROTECTED_ROUTES.any? { |route| request.path.start_with?(route) }
  end

  def self.public_api_path?(request)
    PUBLIC_API_PATH_PREFIXES.any? { |prefix| request.path.starts_with?(prefix) }
  end

  def self.api_request?(request)
    request.path.starts_with?("/api/")
  end

  def self.auth_token(request)
    request.get_header("HTTP_AUTHORIZATION")
  end

  throttle("protected routes (OTP)", limit: 5, period: 20.seconds) do |request|
    request.remote_ip if protected_path?(request)
  end

  # Throttle /api requests by auth token (1000 requests per 5 minutes)
  throttle("API requests by auth token", limit: 1000, period: 5.minutes) do |request|
    if api_request?(request) && !public_api_path?(request)
      auth_token(request)
    end
  end

  # Throttle public /api requests by ip (300 requests per 5 minutes)
  throttle("public API requests by ip", limit: 300, period: 5.minutes) do |request|
    request.ip if public_api_path?(request)
  end

  # Catch all/backstop; throttle all requests by IP (1500 requests per 5 minutes).
  # Important: this should be a higher limit than the other throttles to ensure that
  # it only comes into effect when the other throttles have been exhausted.
  throttle("All other requests by ip", limit: 1500, period: 5.minutes, &:remote_ip)
end

ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, request_id, payload|
  ip = payload.fetch(:request).remote_ip
  path = payload.fetch(:request).fullpath

  Rails.logger.warn("[rack-attack] Throttled request #{request_id} from #{ip} to '#{path}'")
end
