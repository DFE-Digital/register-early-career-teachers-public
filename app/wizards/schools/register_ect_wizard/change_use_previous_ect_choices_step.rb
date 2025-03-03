module Schools
  module RegisterECTWizard
    class ChangeUsePreviousECTChoicesStep < UsePreviousECTChoicesStep
      def previous_step
        :check_answers
      end
    end
  end
end
