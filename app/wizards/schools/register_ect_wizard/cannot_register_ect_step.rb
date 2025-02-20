module Schools
  module RegisterECTWizard
    class CannotRegisterECTStep < Step
      def previous_step
        :find_mentor
      end
    end
  end
end
