module Schools
  module RegisterECTWizard
    class NoPreviousECTChoicesChangeStateSchoolAppropriateBodyStep < StateSchoolAppropriateBodyStep
      def next_step
        :no_previous_ect_choices_change_training_programme
      end

      def previous_step
        :change_use_previous_ect_choices
      end
    end
  end
end
