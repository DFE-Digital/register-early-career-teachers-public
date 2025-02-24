module Sessions
  module Users
    class Builder
      class UnknownProvider < StandardError; end
      class UnknownOrganisation < StandardError; end
      class UnknownPersonaType < StandardError; end

      def id_token = payload.credentials.id_token

      def session_user
        if dfe_sign_in?
          return appropriate_body_user if appropriate_body_user?
          return school_user if school_user?

          raise(UnknownOrganisation, organisation)
        end

        if persona?
          return dfe_persona if dfe_persona?
          return school_persona if school_persona?
          return appropriate_body_persona if appropriate_body_persona?

          raise(UnknownPersonaType)
        end

        raise(UnknownProvider, provider)
      end

    private

      attr_reader :payload

      def initialize(omniauth_payload:)
        @payload = omniauth_payload
      end

      # User info
      def organisation = (@organisation ||= payload.extra.raw_info.organisation)
      def provider = (@provider ||= payload.provider.to_sym)
      def uid = (@uid ||= payload.uid)
      def user_info = (@user_info ||= payload.info)
      def persona? = Rails.application.config.enable_personas && provider == :persona
      def dfe_sign_in? = provider == :dfe_sign_in

      delegate :appropriate_body_id, to: :user_info
      delegate :dfe_staff, to: :user_info
      delegate :email, to: :user_info
      delegate :first_name, to: :user_info
      delegate :last_name, to: :user_info
      delegate :name, to: :user_info
      delegate :school_urn, to: :user_info

      # User?
      def appropriate_body_user? = AppropriateBody.exists?(dfe_sign_in_organisation_id: organisation.id)
      def school_user? = organisation.urn.present? && School.exists?(urn: organisation.urn)
      def appropriate_body_persona? = appropriate_body_id.present?
      def dfe_persona? = ActiveModel::Type::Boolean.new.cast(dfe_staff)
      def school_persona? = school_urn.present?

      # Appropriate Body users
      def appropriate_body_persona
        Sessions::Users::AppropriateBodyPersona.new(email:, name:, appropriate_body_id:)
      end

      def appropriate_body_user
        Sessions::Users::AppropriateBodyUser.new(email:,
                                                 name: [first_name, last_name].join(" "),
                                                 dfe_sign_in_organisation_id: organisation.id,
                                                 dfe_sign_in_user_id: uid)
      end

      # DfE users
      def dfe_persona
        Sessions::Users::DfEPersona.new(email:)
      end

      # School users
      def school_persona
        Sessions::Users::SchoolPersona.new(email:, name:, school_urn:)
      end

      def school_user
        Sessions::Users::SchoolUser.new(email:,
                                        name: [user_info.first_name, user_info.last_name].join(" ").strip,
                                        school_urn: organisation.urn,
                                        dfe_sign_in_organisation_id: organisation.id,
                                        dfe_sign_in_user_id: uid)
      end
    end
  end
end
