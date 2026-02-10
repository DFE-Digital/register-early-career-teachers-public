module Admin
  module Schools
    module AddPartnershipWizard
      class Wizard < ApplicationWizard
        attr_accessor :store, :school_urn, :author

        steps do
          [{
            select_contract_period: SelectContractPeriodStep,
            select_lead_provider: SelectLeadProviderStep,
            select_delivery_partner: SelectDeliveryPartnerStep,
            check_answers: CheckAnswersStep
          }]
        end

        def self.step?(step_name) = Array(steps).first[step_name].present?

        def allowed_steps
          steps = [:select_contract_period]
          return steps if store.contract_period_year.blank?

          steps << :select_lead_provider
          return steps if store.active_lead_provider_id.blank?

          steps << :select_delivery_partner
          return steps if store.delivery_partner_id.blank?

          steps << :check_answers
        end

        def allowed_step_path
          step_path(allowed_steps.last)
        end

        def school
          @school ||= School.includes(:gias_school).find_by!(urn: school_urn)
        end

        def contract_periods
          ContractPeriod.most_recent_first
        end

        def selected_contract_period
          @selected_contract_period ||= ContractPeriod.find_by(year: store.contract_period_year)
        end

        def selected_contract_period_label
          [
            selected_active_lead_provider&.contract_period_year,
            selected_contract_period&.year,
            store.contract_period_year
          ].compact.first&.to_s
        end

        def active_lead_providers
          ActiveLeadProvider
            .for_contract_period_year(store.contract_period_year)
            .with_lead_provider_ordered_by_name
        end

        def selected_active_lead_provider
          return if store.active_lead_provider_id.blank?

          @selected_active_lead_provider ||= ActiveLeadProvider.includes(:lead_provider).find_by(id: store.active_lead_provider_id)
        end

        def selected_lead_provider
          selected_active_lead_provider&.lead_provider
        end

        def delivery_partners
          selected_active_lead_provider&.delivery_partners&.order(:name) || DeliveryPartner.none
        end

        def selected_delivery_partner
          return if store.delivery_partner_id.blank?

          @selected_delivery_partner ||= DeliveryPartner.find_by(id: store.delivery_partner_id)
        end

        def lead_provider_delivery_partnership
          LeadProviderDeliveryPartnership.find_by(
            active_lead_provider: selected_active_lead_provider,
            delivery_partner: selected_delivery_partner
          )
        end

        def current_step_path
          step_path(current_step_name)
        end

        def next_step_path
          step_path(current_step.next_step)
        end

        def previous_step_path
          step_path(current_step.previous_step)
        end

      private

        def step_path(step_name)
          return if step_name.blank?

          Rails.application.routes.url_helpers.public_send(
            "admin_schools_add_partnership_wizard_#{step_name}_path",
            school_urn
          )
        end
      end
    end
  end
end
