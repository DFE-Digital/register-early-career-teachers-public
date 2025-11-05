module Sessions
  module Users
    class AppropriateBodyUser < User
      class UnknownOrganisationId < StandardError; end

      USER_TYPE = :appropriate_body_user
      PROVIDER = :dfe_sign_in

      attr_reader :appropriate_body_period, :dfe_sign_in_organisation_id, :dfe_sign_in_user_id, :name, :dfe_sign_in_roles, :last_active_role

      def initialize(email:, name:, dfe_sign_in_organisation_id:, dfe_sign_in_user_id:, dfe_sign_in_roles: nil, school_urn: nil, last_active_role: self.class.name.demodulize, **)
        @name = name
        @appropriate_body_period = appropriate_body_period_from(dfe_sign_in_organisation_id)
        @dfe_sign_in_organisation_id = dfe_sign_in_organisation_id
        @dfe_sign_in_user_id = dfe_sign_in_user_id
        @dfe_sign_in_roles = dfe_sign_in_roles
        @last_active_role = last_active_role

        super(email:, **)
      end

      delegate :id, to: :appropriate_body_period, prefix: true, allow_nil: true

      def dfe_sign_in_authorisable? = true
      def appropriate_body_user? = true

      def event_author_params
        {
          author_email: email,
          author_name: name,
          author_type: USER_TYPE,
        }
      end

      # @return [String]
      def organisation_name
        if has_multiple_roles?
          appropriate_body_period.name + " (appropriate body)"
        else
          appropriate_body_period.name
        end
      end

      # @return [String]
      def sign_out_path
        "/auth/dfe_sign_in/logout"
      end

      # @return [Hash] session data
      def to_h
        {
          "type" => self.class.name,
          "email" => email,
          "name" => name,
          "last_active_at" => last_active_at,
          "dfe_sign_in_organisation_id" => dfe_sign_in_organisation_id,
          "dfe_sign_in_user_id" => dfe_sign_in_user_id,
          "dfe_sign_in_roles" => dfe_sign_in_roles,
          "last_active_role" => last_active_role,
        }
      end

      # @return [Boolean]
      def has_multiple_roles?
        dfe_sign_in_roles.count > 1
      end

      # @return [Boolean]
      def has_authorised_role?
        (::Organisation::Access::ROLES & dfe_sign_in_roles).any?
      end

      # @return [Array<String>]
      alias_method :roles, :dfe_sign_in_roles

    private

      def appropriate_body_period_from(dfe_sign_in_organisation_id)
        ::AppropriateBodyPeriod.find_by(dfe_sign_in_organisation_id:).tap do |appropriate_body_period|
          raise(UnknownOrganisationId, dfe_sign_in_organisation_id) unless appropriate_body_period
        end
      end
    end
  end
end
