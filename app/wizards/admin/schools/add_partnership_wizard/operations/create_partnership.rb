module Admin
  module Schools
    module AddPartnershipWizard
      module Operations
        class CreatePartnership
          def initialize(step:, **)
            @step = step
          end

          def execute
            wizard = @step.wizard

            SchoolPartnerships::Create.new(
              author: wizard.author,
              school: wizard.school,
              lead_provider_delivery_partnership: wizard.lead_provider_delivery_partnership
            ).create # rubocop:disable Rails/SaveBang

            { success: true }
          end
        end
      end
    end
  end
end
