module Schools
  module RegisterECTWizard
    class NoPreviousECTChoicesChangeStateSchoolAppropriateBodyStep < StateSchoolAppropriateBodyStep
      def next_step
        return :no_previous_ect_choices_change_programme_type if school.programme_choices?

        :check_answers
      end

      def previous_step
        return :change_use_previous_ect_choices if school.programme_choices?

        :check_answers
      end
    end
  end
end
