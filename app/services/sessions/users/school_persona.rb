module Sessions
  module Users
    class SchoolPersona < User
      class SchoolPersonaDisabledError < StandardError; end
      class UnknownSchoolURN < StandardError; end

      USER_TYPE = :school_user
      PROVIDER = :persona

      attr_reader :name, :school

      def initialize(email:, name:, school_urn:, **)
        fail SchoolPersonaDisabledError unless Rails.application.config.enable_personas

        @name = name
        @school = school_from(school_urn)

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

    private

      def school_from(urn)
        ::School.find_by(urn:).tap do |school|
          raise(UnknownSchoolURN, urn) unless school
        end
      end
    end
  end
end
