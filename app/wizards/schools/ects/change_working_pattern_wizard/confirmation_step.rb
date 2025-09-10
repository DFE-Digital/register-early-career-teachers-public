module Schools
  module ECTs
    module ChangeWorkingPatternWizard
      class ConfirmationStep < Step
        def previous_step = :check_answers

        def new_working_pattern = ect_at_school_period.working_pattern
      end
    end
  end
end
