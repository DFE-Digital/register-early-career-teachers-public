module Sessions
  class User
    class UnrecognisedType < StandardError; end

    attr_reader :email, :last_active_at

    MAX_SESSION_IDLE_TIME = 2.hours

    def self.from_session(user_session)
      return unless (type = user_session&.dig('type'))

      user_props = user_session.except('type').symbolize_keys

      case type
      when 'Sessions::Users::AppropriateBodyPersona' then Sessions::Users::AppropriateBodyPersona.new(**user_props)
      when 'Sessions::Users::AppropriateBodyUser' then Sessions::Users::AppropriateBodyUser.new(**user_props)
      when 'Sessions::Users::DfEPersona' then Sessions::Users::DfEPersona.new(**user_props)
      when 'Sessions::Users::DfEUser' then Sessions::Users::DfEUser.new(**user_props)
      when 'Sessions::Users::SchoolPersona' then Sessions::Users::SchoolPersona.new(**user_props)
      when 'Sessions::Users::SchoolUser' then Sessions::Users::SchoolUser.new(**user_props)
      else fail(UnrecognisedType)
      end
    end

    def initialize(email:, last_active_at: Time.zone.now)
      @email = email
      @last_active_at = last_active_at.is_a?(String) ? Time.zone.parse(last_active_at) : last_active_at
    end

    # User?
    def dfe_sign_in_authorisable? = false
    def appropriate_body_user? = user_type == :appropriate_body_user
    def dfe_user? = user_type == :dfe_staff_user
    def school_user? = user_type == :school_user
    def user_type = self.class::USER_TYPE

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
