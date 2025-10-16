module Sessions
  # Current user session base class
  class User
    class UnrecognisedType < StandardError; end

    MAX_SESSION_IDLE_TIME = 2.hours

    # @raise [Sessions::User::UnrecognisedType]
    #
    # @return [Sessions::Users::DfEUser]
    # @return [Sessions::Users::DfEUserImpersonatingSchoolUser]
    # @return [Sessions::Users::DfEPersona]
    # @return [Sessions::Users::AppropriateBodyUser]
    # @return [Sessions::Users::AppropriateBodyPersona]
    # @return [Sessions::Users::SchoolUser]
    # @return [Sessions::Users::SchoolPersona]
    def self.from_session(user_session)
      return unless (type = user_session&.dig("type"))

      user_props = user_session.except("type").symbolize_keys
      type.constantize.new(**user_props)
    rescue NameError
      fail(UnrecognisedType, type)
    end

    attr_reader :email, :last_active_at

    def initialize(email:, last_active_at: Time.zone.now)
      @email = email
      @last_active_at = last_active_at.is_a?(String) ? Time.zone.parse(last_active_at) : last_active_at
    end

    # User?
    def dfe_sign_in_authorisable? = false
    def appropriate_body_user? = false
    def dfe_user? = false
    def school_user? = false
    def dfe_user_impersonating_school_user? = false

    # @return [String] all user types except DfE Sign In
    def sign_out_path
      "/sign-out"
    end

    # @raise [NotImplementedError]
    def to_h
      raise NotImplementedError, "subclasses must be hashable for session storage"
    end

    # @return [nil]
    def last_active_role
      nil
    end

    # @return [Boolean]
    def has_multiple_roles?
      false
    end

    # @return [Boolean]
    def has_authorised_role?
      true
    end

    # @return [Array]
    def roles
      []
    end

    # @return [Boolean]
    def dfe_sign_in?
      provider == :dfe_sign_in
    end

    # @return [Symbol] :dfe_staff_user, :appropriate_body_user, :school_user
    def user_type
      self.class::USER_TYPE
    end

    # @return [Symbol] :otp, :persona, :dfe_sign_in
    def provider
      self.class::PROVIDER
    end

    # Used by Blazer
    # @return [nil]
    def user
      nil
    end

    # @return [Boolean]
    def expired?
      last_active_at < MAX_SESSION_IDLE_TIME.ago
    end

    # @return [Time, nil]
    def expires_at
      (last_active_at + MAX_SESSION_IDLE_TIME) if last_active_at
    end

    # @param time [Time]
    # @return [Time]
    def record_new_activity(time)
      @last_active_at = time
    end
  end
end
