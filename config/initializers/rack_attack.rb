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

  throttle("protected routes (OTP)", limit: 5, period: 20.seconds) do |request|
    request.ip if protected_path?(request)
  end
end

ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, request_id, payload|
  ip = payload.fetch(:request).ip
  path = payload.fetch(:request).fullpath

  Rails.logger.warn("[rack-attack] Throttled request #{request_id} from #{ip} to '#{path}'")
end
