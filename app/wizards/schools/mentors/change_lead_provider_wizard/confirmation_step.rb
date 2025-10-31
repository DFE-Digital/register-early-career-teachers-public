module Schools
  module Mentors
    module ChangeLeadProviderWizard
      class ConfirmationStep < Step
        def previous_step = :check_answers

        def new_lead_provider
          wizard.latest_registration_choice.lead_provider
        end
      end
    end
  end
end
