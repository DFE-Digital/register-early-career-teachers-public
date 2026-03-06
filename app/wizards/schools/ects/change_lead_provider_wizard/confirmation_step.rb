module Schools
  module ECTs
    module ChangeLeadProviderWizard
      class ConfirmationStep < Step
        def previous_step = :check_answers

        def new_lead_provider_name = new_lead_provider&.name

      private

        def new_lead_provider
          @new_lead_provider ||= LeadProvider.find_by(id: store.lead_provider_id)
        end
      end
    end
  end
end
