module Sessions
  module Users
    class SchoolUser < User
      class UnknownOrganisationURN < StandardError; end

      USER_TYPE = :school_user
      PROVIDER = :dfe_sign_in

      attr_reader :name, :school, :school_urn, :gias_school, :dfe_sign_in_organisation_id, :dfe_sign_in_user_id, :dfe_sign_in_roles, :last_active_role

      def initialize(email:, name:, school_urn:, dfe_sign_in_organisation_id:, dfe_sign_in_user_id:, dfe_sign_in_roles:, last_active_role: self.class.name.demodulize, **)
        @name = name
        @school_urn = school_urn
        @school, @gias_school = school_from(school_urn)

        @dfe_sign_in_organisation_id = dfe_sign_in_organisation_id
        @dfe_sign_in_user_id = dfe_sign_in_user_id
        @dfe_sign_in_roles = dfe_sign_in_roles
        @last_active_role = last_active_role

        super(email:, **)
      end

      def dfe_sign_in_authorisable? = true
      def school_user? = true

      def event_author_params
        {
          author_email: email,
          author_name: name,
          author_type: USER_TYPE,
        }
      end

      # @return [String]
      def organisation_name
        school_name = school&.name || gias_school&.name

        if has_multiple_roles?
          "#{school_name} (school)"
        else
          school_name
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
          "school_urn" => school_urn,
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

      def school_from(urn)
        school = ::School.find_by(urn:)
        gias_school = school&.gias_school || ::GIAS::School.find_by(urn:)
        raise(UnknownOrganisationURN, urn) unless school || gias_school

        [school, gias_school]
      end
    end
  end
end
