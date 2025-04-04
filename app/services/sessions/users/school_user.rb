module Sessions
  module Users
    class SchoolUser < User
      class UnknownOrganisationURN < StandardError; end

      USER_TYPE = :school_user
      PROVIDER = :dfe_sign_in

      attr_reader :name, :school, :dfe_sign_in_organisation_id, :dfe_sign_in_user_id

      def initialize(email:, name:, school_urn:, dfe_sign_in_organisation_id:, dfe_sign_in_user_id:, **)
        @name = name
        @school = school_from(school_urn)
        @dfe_sign_in_organisation_id = dfe_sign_in_organisation_id
        @dfe_sign_in_user_id = dfe_sign_in_user_id

        super(email:, **)
      end

      def dfe_sign_in_authorisable? = true

      def event_author_params
        {
          author_email: email,
          author_name: name,
          author_type: USER_TYPE,
        }
      end

      def organisation_name = school.name

      delegate :urn, to: :school, prefix: true, allow_nil: true

      def sign_out_path = '/auth/dfe_sign_in/logout'

      def to_h
        {
          "type" => self.class.name,
          "email" => email,
          "name" => name,
          "last_active_at" => last_active_at,
          "school_urn" => school_urn,
          "dfe_sign_in_organisation_id" => dfe_sign_in_organisation_id,
          "dfe_sign_in_user_id" => dfe_sign_in_user_id
        }
      end

    private

      def school_from(urn)
        ::School.find_by(urn:).tap do |school|
          raise(UnknownOrganisationURN, urn) unless school
        end
      end
    end
  end
end
