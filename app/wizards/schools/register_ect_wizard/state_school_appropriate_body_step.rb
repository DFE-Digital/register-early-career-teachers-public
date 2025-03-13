module Schools
  module RegisterECTWizard
    class StateSchoolAppropriateBodyStep < Step
      attr_accessor :appropriate_body_id

      # OPTIMIZE: Validate appropriate_body_id against a list of known appropriate bodies
      validates :appropriate_body_id, presence: {
        message: "Enter the name of the appropriate body which will be supporting the ECT's induction"
      }

      def self.permitted_params
        %i[appropriate_body_id]
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
        ect.update!(appropriate_body_type: 'teaching_school_hub', appropriate_body_id:)
      end
    end
  end
end
