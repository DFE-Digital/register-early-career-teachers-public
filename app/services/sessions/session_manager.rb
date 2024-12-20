module Sessions
  class SessionManager
    class MissingAccessLevel < StandardError; end

    attr_reader :session

    def initialize(session)
      @session = session
    end

    ###########################
    def begin_dfe_sign_in_session!(user_info)
      session_user = SessionUser.from_dfe_sign_in(user_info)

      fail(MissingAccessLevel) unless dfe_sign_in_user_has_access?(user_id: session_user.dfe_sign_in_user_id,
                                                                   organisation_id: session_user.dfe_sign_in_organisation_id)
    end


    def begin_session!(session_user)
      @current_user = nil
      session['user_session'] = session_user.to_h
    end

    def current_user
      @current_user ||= load_from_session
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

  private

    def load_from_session
      return if session['user_session'].blank?

      Sessions::SessionUser.from_session(session['user_session']).tap do |session_user|
        return(nil) if session_user.nil?
        return(nil) if session_user.expired?

        record_new_activity(session_user)
      end
    end

    def record_new_activity(session_user)
      session['user_session']['last_active_at'] = session_user.record_new_activity(Time.current)
    end

    ##########################
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
