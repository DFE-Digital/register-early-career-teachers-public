module Sessions
  class Manager
    class MissingAccessLevel < StandardError; end

    attr_reader :session

    def initialize(session)
      @session = session
    end

    def begin_session!(session_user)
      check_authorisation!(session_user)
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

    def check_authorisation!(session_user)
      return unless session_user.dfe_sign_in_authorisable?
      return if Organisation::Access.new(user_id: session_user.dfe_sign_in_user_id,
                                         organisation_id: session_user.dfe_sign_in_organisation_id)
                                    .can_access?

      fail(MissingAccessLevel)
    end

    def load_from_session
      Sessions::User.from_session(session['user_session']).tap do |session_user|
        return(nil) if session_user.nil?
        return(nil) if session_user.expired?

        record_new_activity(session_user)
      end
    end

    def record_new_activity(session_user)
      session['user_session']['last_active_at'] = session_user.record_new_activity(Time.current)
    end
  end
end
