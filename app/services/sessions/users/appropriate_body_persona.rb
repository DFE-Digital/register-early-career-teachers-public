module Sessions
  module Users
    class AppropriateBodyPersona < User
      class AppropriateBodyPersonaDisabledError < StandardError; end

      USER_TYPE = :appropriate_body_user
      PROVIDER = :persona

      attr_reader :appropriate_body, :name

      def initialize(email:, name:, appropriate_body_id:, **)
        fail AppropriateBodyPersonaDisabledError unless Rails.application.config.enable_personas

        @appropriate_body = AppropriateBody.find(appropriate_body_id)
        @name = name

        super(email:, **)
      end

      delegate :id, to: :appropriate_body, prefix: true, allow_nil: true

      def event_author_params
        {
          author_email: email,
          author_name: name,
          author_type: USER_TYPE,
        }
      end

      def organisation_name = appropriate_body.name

      def sign_out_path = '/sign-out'

      def to_h
        {
          "type" => self.class.name,
          "email" => email,
          "name" => name,
          "last_active_at" => last_active_at,
          "appropriate_body_id" => appropriate_body_id
        }
      end
    end
  end
end
