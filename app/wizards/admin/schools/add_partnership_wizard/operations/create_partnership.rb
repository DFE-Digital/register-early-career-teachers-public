module Admin
  module Schools
    module AddPartnershipWizard
      class CreatePartnership
        REQUIRED_ANSWERS = %i[
          contract_period_year
          framework_agreement_id
          delivery_partner_id
        ].freeze

        def initialize(repository:, step:)
          @repository = repository
          @step = step
        end

        def execute
          if REQUIRED_ANSWERS.any? { |key| @repository.read[key].blank? }
            raise ApplicationWizardStep::EmptyStoreError
          end

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
