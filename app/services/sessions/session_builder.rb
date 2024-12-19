module Sessions
  class SessionBuilder
    class UnknownProvider < StandardError; end

    attr_reader :provider, :session_manager, :user_info, :params

    def initialize(provider, session_manager:, user_info:, params:)
      @provider = provider
      @session_manager = session_manager
      @user_info = user_info
      @params = params
    end

    def build!
      case provider
      when "developer"
        dfe = ActiveModel::Type::Boolean.new.cast(params['dfe'])

        dfe ? begin_otp_session(user_info) : begin_persona_session(user_info)
      when "dfe_sign_in"
        session_manager.begin_dfe_sign_in_session!(user_info)
      else
        raise UnknownProvider, provider
      end
    end

  private

    def begin_persona_session(user_info)
      session_manager.begin_persona_session!(
        user_info.info.email,
        name: user_info.info.name,
        appropriate_body_id: params["appropriate_body_id"].presence,
        school_urn: params["school_urn"].presence
      )
    end

    def begin_otp_session(user_info)
      session_manager.begin_otp_session!(user_info.info.email)
    end
  end
end
