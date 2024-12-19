module Sessions
  class SessionManager
    class MissingAccessLevel < StandardError; end

    MAX_SESSION_IDLE_TIME = 2.hours

    attr_reader :session

    delegate :provider, to: :current_user

    def initialize(session)
      @session = session
    end

    def begin_otp_session!(email)
      session['user_session'] = SessionUser.from_user_record(email:, provider: 'otp').to_h
    end

    def begin_persona_session!(email, name: nil, appropriate_body_id: nil, school_urn: nil)
      session['user_session'] = SessionUser.new(provider: 'developer', email:, name:, appropriate_body_id:, school_urn:).to_h
    end

    def begin_dfe_sign_in_session!(user_info)
      session_user = SessionUser.from_dfe_sign_in(user_info)

      fail(MissingAccessLevel) unless dfe_sign_in_user_has_access?(user_id: session_user.dfe_sign_in_user_id,
                                                                   organisation_id: session_user.dfe_sign_in_organisation_id)

      session['user_session'] = session_user.to_h
    end

    def load_from_session
      return if current_user.blank?

      return if expired?

      current_user.record_new_activity!(session:)
    end

    def end_session!
      session.destroy
    end

    def requested_path=(path)
      session[:requested_path] = path
    end

    def requested_path
      session.delete(:requested_path)
    end

    def expired?
      return true unless last_active_at

      last_active_at < MAX_SESSION_IDLE_TIME.ago
    end

    def expires_at
      (last_active_at + MAX_SESSION_IDLE_TIME) if last_active_at
    end

  private

    def current_user
      return if session['user_session'].blank?

      @current_user ||= Sessions::SessionUser.from_session(session['user_session'])
    end

    def current_session
      @current_session ||= session["user_session"]
    end

    def last_active_at
      return if current_user.blank?

      current_user.last_active_at
    end

    def email
      return if current_user.blank?

      current_user.email
    end

    def dfe_sign_in_user_has_access?(organisation_id:, user_id:)
      access_level = dfe_sign_in_api_client.access_levels(organisation_id:, user_id:)

      Rails.logger.info(access_level)

      access_level.has_register_ect_access_role?
    end

    def dfe_sign_in_api_client
      @dfe_sign_in_api_client ||= DfESignIn::APIClient.new
    end
  end
end
