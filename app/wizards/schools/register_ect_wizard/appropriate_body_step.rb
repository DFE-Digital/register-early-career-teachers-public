module Schools
  module RegisterECTWizard
    class AppropriateBodyStep < Step
      attr_accessor :appropriate_body_id

      validates :appropriate_body, appropriate_body: true

      def self.permitted_params
        %i[appropriate_body_id]
      end

      def appropriate_body
        @appropriate_body ||= AppropriateBody.find_by_id(appropriate_body_id) if appropriate_body_id
      end

      # appropriate_body_type
      delegate :type, to: :appropriate_body, prefix: true, allow_nil: true

      def next_step
        :programme_type
      end

      def previous_step
        return :use_previous_ect_choices if school.programme_choices?

        :working_pattern
      end
    end
  end
end
