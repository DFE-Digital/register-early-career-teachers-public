module Admin
  module Teachers
    module UndoRegistrationWizard
      class TrainingPeriodSummaryComponent < ApplicationComponent
        attr_reader :training_period, :end_date

        def initialize(training_period:, end_date:)
          @training_period = training_period
          @end_date = end_date
        end

      private

        def card_title
          return "School-led training programme" if training_period.school_led_training_programme?
          return "#{training_period.lead_provider_name} & #{training_period.delivery_partner_name}" if confirmed_partnership?

          lead_provider_name || "Provider-led training programme"
        end

        def lead_provider_name
          return training_period.lead_provider_name if confirmed_partnership?

          training_period.expression_of_interest_lead_provider&.name
        end

        def delivery_partner_name
          return training_period.delivery_partner_name if confirmed_partnership?

          "No delivery partner confirmed"
        end

        def contract_period_year
          training_period.contract_period&.year ||
            training_period.expression_of_interest_contract_period&.year
        end

        def confirmed_partnership?
          training_period.school_partnership.present?
        end
      end
    end
  end
end
