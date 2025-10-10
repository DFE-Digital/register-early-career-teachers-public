module Schools
  module ECTs
    module ChangeLeadProviderWizard
      class ConfirmationStep < Step
        def previous_step = :check_answers
      end
    end
  end
end
