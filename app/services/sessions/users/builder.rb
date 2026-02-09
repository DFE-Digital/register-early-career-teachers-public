module Sessions
  module Users
    # Checks for a matching AppropriateBody or School record and the correct DfE Sign In policy role
    # OTP is currently used for DfE Users in production
    class Builder
      class UnknownProvider < StandardError; end
      class UnknownOrganisation < StandardError; end
      class UnknownPersonaType < StandardError; end

      # @param omniauth_payload [OmniAuth::AuthHash]
      def initialize(omniauth_payload:)
        @payload = omniauth_payload
      end

      # @see SessionsController#create
      # @return [String]
      def id_token
        payload.credentials.id_token
      end

      # @return [String]
      delegate :name, to: :organisation, prefix: true

      # Determine user session type
      #
      # NB: Sessions::Users::DfEUser is only returned for local development currently
      # @see OTPSessionsController#session_user
      #
      # @raise [Sessions::Users::UnknownOrganisation]
      # @raise [Sessions::Users::UnknownPersonaType]
      # @raise [Sessions::Users::UnknownProvider]
      #
      # @return [Sessions::Users::DfEUser] # TODO: deprecate OTP
      # @return [Sessions::Users::DfEPersona]
      # @return [Sessions::Users::AppropriateBodyUser]
      # @return [Sessions::Users::AppropriateBodyPersona]
      # @return [Sessions::Users::SchoolUser]
      # @return [Sessions::Users::SchoolPersona]
      def session_user
        if dfe_sign_in?
          return school_user if school_user?
          return appropriate_body_user if appropriate_body_user?
          return dfe_user if dfe_user? # TODO: deprecate OTP

          raise(UnknownOrganisation, organisation)
        end

        if persona?
          return school_persona if school_persona?
          return appropriate_body_persona if appropriate_body_persona?
          return dfe_persona if dfe_persona?

          raise(UnknownPersonaType)
        end

        raise(UnknownProvider, provider)
      end

    private

      delegate :appropriate_body_id, to: :user_info

      # @return [Sessions::Users::AppropriateBodyPersona]
      def appropriate_body_persona
        AppropriateBodyPersona.new(email:, name:, appropriate_body_id:)
      end

      # @return [Boolean]
      def appropriate_body_persona?
        appropriate_body_id.present?
      end

      # @return [Sessions::Users::AppropriateBodyUser]
      def appropriate_body_user
        AppropriateBodyUser.new(email:,
                                name: full_name,
                                dfe_sign_in_organisation_id: organisation.id,
                                dfe_sign_in_user_id: uid,
                                dfe_sign_in_roles:)
      end

      # @return [Boolean]
      def appropriate_body_user?
        organisation.id.present? &&
          ::AppropriateBody.exists?(dfe_sign_in_organisation_id: organisation.id) &&
          dfe_sign_in_roles.include?("AppropriateBodyUser")
      end

      # @return [Sessions::Users::DfEPersona]
      def dfe_persona
        DfEPersona.new(email:)
      end

      # @return [Boolean]
      def dfe_persona?
        ActiveModel::Type::Boolean.new.cast(dfe_staff)
      end

      # @return [Boolean]
      def dfe_sign_in?
        provider == :dfe_sign_in
      end

      # Query the DfE Sign In API
      # @return [Array<String>] SchoolUser, AppropriateBodyUser, DfEUser
      def dfe_sign_in_roles
        @dfe_sign_in_roles ||= ::Organisation::Access.new(user_id: uid, organisation_id: organisation.id).roles
      end

      delegate :dfe_staff, to: :user_info

      # TODO: deprecate OTP
      # @return [Sessions::Users::DfEUser]
      def dfe_user
        DfEUser.new(email:)
      end

      # TODO: deprecate OTP
      # @return [Boolean]
      def dfe_user?
        Rails.env.development? && ::User.exists?(email:)
      end

      delegate :email, to: :user_info
      delegate :first_name, to: :user_info

      # @return [String]
      def full_name
        [first_name, last_name].join(" ").strip
      end

      delegate :last_name, to: :user_info
      delegate :name, to: :user_info

      # @return [OmniAuth::AuthHash]
      def organisation
        @organisation ||= payload.extra.raw_info.organisation
      end

      attr_reader :payload

      # @return [Boolean]
      def persona?
        Rails.application.config.enable_personas && provider == :persona
      end

      # @return [Symbol] :dfe_sign_in, :persona
      def provider
        @provider ||= payload.provider.to_sym
      end

      # @return [Sessions::Users::SchoolPersona]
      def school_persona
        SchoolPersona.new(email:, name:, school_urn:)
      end

      # @return [Boolean]
      def school_persona?
        school_urn.present?
      end

      delegate :school_urn, to: :user_info

      # @return [Sessions::Users::SchoolUser]
      def school_user
        SchoolUser.new(email:,
                       name: full_name,
                       school_urn: organisation.urn,
                       dfe_sign_in_organisation_id: organisation.id,
                       dfe_sign_in_user_id: uid,
                       dfe_sign_in_roles:)
      end

      # @return [Boolean]
      def school_user?
        organisation.urn.present? &&
          (School.exists?(urn: organisation.urn) || GIAS::School.exists?(urn: organisation.urn)) &&
          dfe_sign_in_roles.include?("SchoolUser")
      end

      # @return [String]
      def uid
        @uid ||= payload.uid
      end

      # @return [OmniAuth::AuthHash::InfoHash]
      def user_info
        @user_info ||= payload.info
      end
    end
  end
end
