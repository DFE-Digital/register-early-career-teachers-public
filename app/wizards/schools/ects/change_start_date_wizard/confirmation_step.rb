module Schools
  module ECTs
    module ChangeStartDateWizard
      class ConfirmationStep < Step
        def previous_step = :check_answers

        def new_start_date
          ect_at_school_period.started_on
        end
      end
    end
  end
end
