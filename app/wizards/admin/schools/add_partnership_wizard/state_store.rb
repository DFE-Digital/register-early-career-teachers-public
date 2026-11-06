module Admin
  module Schools
    module AddPartnershipWizard
      class StateStore
        include DfE::Wizard::StateStore

        attr_reader :school

        def initialize(school:, **kwargs)
          @school = school
          super(**kwargs)
        end

        def contract_periods
          ContractPeriod.most_recent_first
        end

        def selected_contract_period
          @selected_contract_period ||= ContractPeriod.find_by(
            year: contract_period_year
          )
        end

        def selected_contract_period_label
          [
            selected_framework_agreement&.contract_period_year,
            selected_contract_period&.year,
            contract_period_year
          ].compact.first&.to_s
        end

        def framework_agreements
          FrameworkAgreement
            .for_contract_period_year(contract_period_year)
            .with_lead_provider_ordered_by_name
        end

        def selected_framework_agreement
          return if framework_agreement_id.blank?

          @selected_framework_agreement ||= FrameworkAgreement
            .includes(:lead_provider)
            .find_by(id: framework_agreement_id)
        end

        def selected_lead_provider
          selected_framework_agreement&.lead_provider
        end

        def delivery_partners
          selected_framework_agreement&.delivery_partners&.order(:name) ||
            DeliveryPartner.none
        end

        def selected_delivery_partner
          return if delivery_partner_id.blank?

          @selected_delivery_partner ||= DeliveryPartner.find_by(
            id: delivery_partner_id
          )
        end

        def lead_provider_delivery_partnership
          LeadProviderDeliveryPartnership.find_by(
            framework_agreement: selected_framework_agreement,
            delivery_partner: selected_delivery_partner
          )
        end
      end
    end
  end
end
