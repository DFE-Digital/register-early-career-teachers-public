class Rack::Attack
  PROTECTED_ROUTES = %w[
    /otp-sign-in
    /otp-sign-in/code
    /otp-sign-in/verify
    /sign-in
    /auth
    /healthcheck
  ].freeze

  def self.protected_path?(request)
    PROTECTED_ROUTES.any? { |route| request.path.start_with?(route) }
  end

  def self.api_request?(request)
    request.path.starts_with?("/api/")
  end

  def self.auth_token(request)
    request.get_header("HTTP_AUTHORIZATION")
  end

  throttle("protected routes (OTP)", limit: 5, period: 20.seconds) do |request|
    request.ip if protected_path?(request)
  end

  # Throttle /api requests by auth token (1000 requests per 5 minutes)
  throttle("API requests by auth token", limit: 1000, period: 5.minutes) do |request|
    auth_token(request) if api_request?(request) && !protected_path?(request)
  end
end

ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, request_id, payload|
  ip = payload.fetch(:request).ip
  path = payload.fetch(:request).fullpath

  Rails.logger.warn("[rack-attack] Throttled request #{request_id} from #{ip} to '#{path}'")
end
