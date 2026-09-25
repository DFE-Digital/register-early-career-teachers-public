module API::OAuth::TokenAuthenticable
  extend ActiveSupport::Concern
  include ActionController::HttpAuthentication::Token::ControllerMethods

  included do
    before_action :authenticate
    attr_reader :current_authorization
  end

private

  def authenticate
    authenticate_request || render_unauthorized
  end

  def authenticate_request
    authenticate_with_http_token do |token|
      @current_authorization = API::OAuth::Authorization.active.with_token(token).take
    end
  end

  def render_unauthorized
    if request.authorization.present?
      headers["WWW-Authenticate"] = %(Bearer error="invalid_token")
      render json: API::OAuth::ErrorSerializer.render({ error: "invalid_token" }), status: :unauthorized
    else
      headers["WWW-Authenticate"] = "Bearer"
      head :unauthorized
    end
  end
end
