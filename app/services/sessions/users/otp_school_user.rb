module Sessions
  module Users
    class OTPSchoolUser < User
      class UnknownOrganisationURN < StandardError; end

      USER_TYPE = :school_user
      PROVIDER = :otp

      attr_reader :name, :school, :school_urn, :gias_school

      def initialize(email:, name:, school_urn:, **)
        @name = name
        @school_urn = school_urn
        @school, @gias_school = school_from(school_urn)

        super(email:, **)
      end

      def school_user? = true

      def event_author_params
        {
          author_email: email,
          author_name: name,
          author_type: USER_TYPE,
        }
      end

      def organisation_name
        school&.name || gias_school&.name
      end

      def sign_out_path
        "/sign-out"
      end

      def to_h
        {
          "type" => self.class.name,
          "email" => email,
          "name" => name,
          "last_active_at" => last_active_at,
          "school_urn" => school_urn,
        }
      end

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
