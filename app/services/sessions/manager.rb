module Sessions
  # Begin and end user sessions
  # Edit session and cookie attributes
  # Define the current user
  # Check role based access
  # Handle role switching

  class Manager
    class MissingAccessLevel < StandardError; end

    attr_reader :session, :cookies

    # @param session [ActionDispatch::Request::Session]
    # @param cookies [ActionDispatch::Cookies::CookieJar]
    def initialize(session, cookies)
      @session = session
      @cookies = cookies
    end

    # @see Sessions::Users::Builder#session_user
    def begin_session!(session_user, id_token: "")
      check_authorisation!(session_user)
      @current_user = nil
      session["user_session"] = session_user.to_h
      cookies["id_token"] = encrypt_token(id_token)
    end

    # @see Sessions::User
    # @raise [Sessions::User::UnrecognisedType]
    # @return [Sessions::User]
    def current_user
      @current_user ||= load_from_session
    end

    # NB: when switching between School and AB roles we need to set the record identifier
    # - URN for SchoolUser
    # - DfE Org ID for AppropriateBodyUser
    #
    # OPTIMIZE: this would be trivial if we saved the dfe_sign_in_organisation_id on the School record the same way we do for AppropriateBody
    #
    def switch_role!
      new_role = current_user.dfe_sign_in_roles.find { |role| role != current_user.last_active_role }

      session["user_session"]["last_active_role"] = new_role # replace the last active role
      session["user_session"]["type"] = "Sessions::Users::#{new_role}" # update the user type in the session

      if current_user.dfe_sign_in_organisation_id
        appropriate_body = AppropriateBody.find_by(dfe_sign_in_organisation_id: current_user.dfe_sign_in_organisation_id)
        gias_school = GIAS::School.find_by(name: appropriate_body.name)

        session["user_session"]["school_urn"] ||= gias_school.urn

      elsif current_user.school_urn
        gias_school = GIAS::School.find_by(urn: current_user.school_urn)
        appropriate_body = AppropriateBody.find_by(name: gias_school.name)

        session["user_session"]["dfe_sign_in_organisation_id"] ||= appropriate_body.dfe_sign_in_organisation_id
      end

      @current_user = load_from_session
    end

    def end_session!
      session.destroy
      cookies.delete("id_token")
    end

    def requested_path=(path)
      session[:requested_path] = path
    end

    def requested_path
      session.delete(:requested_path)
    end

  private

    # @see https://github.com/DFE-Digital/login.dfe.public-api
    # @param session_user [Sessions::User]
    # @raise [Sessions::Manager::MissingAccessLevel]
    def check_authorisation!(session_user)
      return if session_user.has_authorised_role?

      fail(MissingAccessLevel, "#{session_user.email} with role(s) #{session_user.roles.to_sentence}")
    end

    def encrypt_token(token)
      secret_key = Rails.application.secret_key_base.byteslice(0, 32)
      encryptor = ActiveSupport::MessageEncryptor.new(secret_key)
      Base64.strict_encode64(Zlib::Deflate.deflate(encryptor.encrypt_and_sign(token)))
    end

    # @return [Sessions::Users]
    def load_from_session
      Sessions::User.from_session(session["user_session"]).tap do |session_user|
        return (nil) if session_user.nil?
        return (nil) if session_user.expired?

        record_new_activity(session_user)
      end
    rescue ArgumentError => e
      Sentry.capture_exception(e)
      end_session!
    end

    def record_new_activity(session_user)
      session["user_session"]["last_active_at"] = session_user.record_new_activity(Time.current)
    end
  end
end
