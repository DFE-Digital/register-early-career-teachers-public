module Sessions
  module Users
    class SchoolPersona < User
      USER_TYPE = :school_user
      PROVIDER = :persona

      attr_reader :name, :school

      def initialize(email:, name:, school_urn:, **)
        @name = name
        @school = School.find_by!(urn: school_urn)

        super(email:, **)
      end

      def event_author_params
        {
          author_email: email,
          author_name: name,
          author_type: USER_TYPE,
        }
      end

      def organisation_name = school.name

      delegate :urn, to: :school, prefix: true, allow_nil: true

      def sign_out_path = '/sign-out'

      def to_h
        {
          "type" => self.class.name,
          "email" => email,
          "name" => name,
          "last_active_at" => last_active_at,
          "school_urn" => school_urn.presence,
        }
      end
    end
  end
end
