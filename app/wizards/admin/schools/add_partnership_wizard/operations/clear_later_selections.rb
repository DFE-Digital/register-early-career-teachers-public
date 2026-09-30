module Admin
  module Schools
    module AddPartnershipWizard
      class ClearLaterSelections
        def initialize(repository:, step:)
          @repository = repository
          @step = step
        end

        def execute
          case @step.step_id
          when :select_contract_period
            @repository.write(framework_agreement_id: nil, delivery_partner_id: nil)
          when :select_lead_provider
            @repository.write(delivery_partner_id: nil)
          end

          { success: true }
        end
      end
    end
  end
end
