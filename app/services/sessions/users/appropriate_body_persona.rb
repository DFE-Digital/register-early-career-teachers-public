module Sessions
  module Users
    class AppropriateBodyPersona < User
      class AppropriateBodyPersonaDisabledError < StandardError; end
      class UnknownAppropriateBodyId < StandardError; end

      USER_TYPE = :appropriate_body_user
      PROVIDER = :persona

      attr_reader :appropriate_body, :name

      def initialize(email:, name:, appropriate_body_id:, **)
        fail AppropriateBodyPersonaDisabledError unless Rails.application.config.enable_personas

        @appropriate_body = appropriate_body_from(appropriate_body_id)
        @name = name

        super(email:, **)
      end

      delegate :id, to: :appropriate_body, prefix: true, allow_nil: true

      def appropriate_body_user? = true

      def event_author_params
        {
          author_email: email,
          author_name: name,
          author_type: USER_TYPE,
        }
      end

      def organisation_name = appropriate_body.name

      # @return [Hash] session data
      def to_h
        {
          "type" => self.class.name,
          "email" => email,
          "name" => name,
          "last_active_at" => last_active_at,
          "appropriate_body_id" => appropriate_body_id
        }
      end

    private

      def appropriate_body_from(appropriate_body_id)
        ::AppropriateBody.find_by_id(appropriate_body_id).tap do |appropriate_body|
          raise(UnknownAppropriateBodyId, appropriate_body_id) unless appropriate_body
        end
      end
    end
  end
end
