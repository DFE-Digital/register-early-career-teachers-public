module Admin
  module Schools
    class AddPartnershipReview
      include DfE::Wizard::CheckAnswersPresenter

      def partnership_details
        [
          row_for(
            :select_contract_period,
            :contract_period_year,
            label: "Contract period"
          ),
          row_for(
            :select_lead_provider,
            :framework_agreement_id,
            label: "Lead provider"
          ),
          row_for(
            :select_delivery_partner,
            :delivery_partner_id,
            label: "Delivery partner"
          )
        ]
      end

      def format_value(attribute, value)
        case attribute
        when :contract_period_year
          wizard.selected_contract_period_label
        when :framework_agreement_id
          wizard.selected_lead_provider&.name
        when :delivery_partner_id
          wizard.selected_delivery_partner&.name
        else
          value
        end
      end
    end
  end
end
