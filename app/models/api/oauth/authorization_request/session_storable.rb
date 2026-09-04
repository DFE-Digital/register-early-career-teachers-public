module API::OAuth::AuthorizationRequest::SessionStorable
  extend ActiveSupport::Concern

  SESSION_KEY = :oauth_authorization_request

  class_methods do
    def build(authorization_request_params)
      new(**authorization_request_params)
    end

    def from(session)
      return if session[SESSION_KEY].blank?

      new(**session[SESSION_KEY].symbolize_keys)
    end

    def clear_from(session)
      session.delete(SESSION_KEY)
    end
  end

  def store_in(session)
    session[SESSION_KEY] = attributes
  end
end
