module Schools
  module RegisterECTWizard
    class ChangeStateSchoolAppropriateBodyStep < StateSchoolAppropriateBodyStep
      def next_step
        return :change_programme_type if school.programme_choices?

        :check_answers
      end

      def previous_step
        return :change_use_previous_ect_choices if school.programme_choices?

        :check_answers
      end
    end
  end
end
