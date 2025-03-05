module Schools
  module RegisterECTWizard
    class UsePreviousECTChoicesStep < Step
      attribute :use_previous_ect_choices, :boolean

      validates :use_previous_ect_choices,
                inclusion: {
                  in: [true, false],
                  message: "Select 'Yes' or 'No' to confirm whether to use the programme choices used by your school previously"
                }

      def self.permitted_params
        %i[use_previous_ect_choices]
      end

      def next_step
        return :check_answers if use_previous_ect_choices
        return :independent_school_appropriate_body if school.independent?

        :state_school_appropriate_body
      end

      def previous_step
        :working_pattern
      end

    private

      def choices = use_previous_ect_choices ? school.programme_choices : {}

      def persist
        ect.update!(use_previous_ect_choices:, **choices)
      end
    end
  end
end
