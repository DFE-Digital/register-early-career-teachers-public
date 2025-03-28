module Schools
  module RegisterECTWizard
    class IndependentSchoolAppropriateBodyStep < Step
      attr_accessor :appropriate_body_id, :appropriate_body_type

      validates_with AppropriateBodyValidator

      def self.permitted_params
        %i[appropriate_body_id appropriate_body_type]
      end

      def next_step
        :programme_type
      end

      def previous_step
        return :use_previous_ect_choices if school.programme_choices?

        :working_pattern
      end

    private

      def persist
        ect.update!(appropriate_body_id:, appropriate_body_type:)
      end
    end
  end
end
