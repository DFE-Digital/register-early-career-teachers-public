module Sessions
  class SessionUser
    attr_reader :email, :last_active_at

    MAX_SESSION_IDLE_TIME = 2.hours

    def self.from_session(user_session)
      session_user_class = user_session['type']&.constantize
      session_user_class.new(**user_session.except('type').symbolize_keys) if session_user_class
    end

    def initialize(email:, last_active_at: Time.zone.now)
      @email = email
      @last_active_at = last_active_at.is_a?(String) ? Time.zone.parse(last_active_at) : last_active_at
    end

    # User?
    def appropriate_body_user? = false
    def dfe_user? = false
    def school_user? = false
    def dfe_sign_in_authorisable? = false

    # Activity
    def expired?
      last_active_at < MAX_SESSION_IDLE_TIME.ago
    end

    def expires_at
      (last_active_at + MAX_SESSION_IDLE_TIME) if last_active_at
    end

    def record_new_activity(time)
      @last_active_at = time
    end
  end
end
