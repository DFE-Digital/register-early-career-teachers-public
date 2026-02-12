module Sessions
  module Users
    class AppropriateBodyPersona < User
      class AppropriateBodyPersonaDisabledError < StandardError; end
      class UnknownAppropriateBodyPeriodId < StandardError; end

      USER_TYPE = :appropriate_body_user
      PROVIDER = :persona

      attr_reader :appropriate_body_period, :name

      def initialize(email:, name:, appropriate_body_period_id:, **)
        fail AppropriateBodyPersonaDisabledError unless Rails.application.config.enable_personas

        @appropriate_body_period = appropriate_body_period_from(appropriate_body_period_id)
        @name = name

        super(email:, **)
      end

      delegate :id, to: :appropriate_body_period, prefix: true, allow_nil: true

      def appropriate_body_user? = true

      def event_author_params
        {
          author_email: email,
          author_name: name,
          author_type: USER_TYPE,
        }
      end

      def organisation_name = appropriate_body_period.name

      # @return [Hash] session data
      def to_h
        {
          "type" => self.class.name,
          "email" => email,
          "name" => name,
          "last_active_at" => last_active_at,
          "appropriate_body_period_id" => appropriate_body_period_id
        }
      end

    private

      def appropriate_body_period_from(appropriate_body_period_id)
        ::AppropriateBodyPeriod.find_by_id(appropriate_body_period_id).tap do |appropriate_body_period|
          raise(UnknownAppropriateBodyPeriodId, appropriate_body_period_id) unless appropriate_body_period
        end
      end
    end
  end
end
