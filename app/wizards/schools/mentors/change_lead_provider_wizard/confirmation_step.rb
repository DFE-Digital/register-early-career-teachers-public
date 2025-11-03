module Schools
  module Mentors
    module ChangeLeadProviderWizard
      class ConfirmationStep < Step
        def previous_step = :check_answers

        def new_lead_provider_name = new_lead_provider&.name

      private

        def new_lead_provider
          @new_lead_provider ||= current_training_period&.active_lead_provider&.lead_provider || current_training_period&.expression_of_interest&.lead_provider
        end

        def current_training_period
          mentor_at_school_period.current_or_next_training_period
        end
      end
    end
  end
end
