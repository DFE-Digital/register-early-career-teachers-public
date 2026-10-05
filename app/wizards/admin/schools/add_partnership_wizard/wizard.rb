module Admin
  module Schools
    module AddPartnershipWizard
      class Wizard
        include DfE::Wizard

        def self.routes = %i[
          select_contract_period
          select_lead_provider
          select_delivery_partner
          check_answers
        ]

        attr_reader :school_urn, :author

        def initialize(school_urn:, author:, state_store:, current_step:, current_step_params: {})
          @school_urn = school_urn
          @author = author
          super(state_store:, current_step:, current_step_params:)
        end

        def steps_processor
          DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
            graph.add_node :select_contract_period, SelectContractPeriodStep
            graph.add_node :select_lead_provider, SelectLeadProviderStep
            graph.add_node :select_delivery_partner, SelectDeliveryPartnerStep
            graph.add_node :check_answers, CheckAnswersStep

            graph.root :select_contract_period
            graph.add_edge from: :select_contract_period, to: :select_lead_provider
            graph.add_edge from: :select_lead_provider, to: :select_delivery_partner
            graph.add_edge from: :select_delivery_partner, to: :check_answers
          end
        end

        def steps_operator
          DfE::Wizard::StepsOperator::Builder.draw(wizard: self, callable: state_store) do |builder|
            builder.on_step(
              :select_contract_period,
              use: [
                DfE::Wizard::Operations::Validate,
                Operations::ClearLaterSelections,
                DfE::Wizard::Operations::Persist
              ]
            )

            builder.on_step(
              :select_lead_provider,
              use: [
                DfE::Wizard::Operations::Validate,
                Operations::ClearLaterSelections,
                DfE::Wizard::Operations::Persist
              ]
            )

            builder.on_step(
              :check_answers,
              use: [DfE::Wizard::Operations::Validate, Operations::CreatePartnership]
            )
          end
        end

        def route_strategy
          DfE::Wizard::RouteStrategy::ConfigurableRoutes.new(
            wizard: self,
            namespace: :admin_schools_add_partnership_wizard
          ) do |routes|
            routes.default_path_arguments = { school_urn: }
          end
        end

        def furthest_valid_step_path
          step_id = root_step

          while valid?(step_id) && (next_step_id = steps_processor.next_step(step_id))
            step_id = next_step_id
          end

          resolve_step_path(step_id)
        end

        def school
          @school ||= School.includes(:gias_school).find_by!(urn: school_urn)
        end

        def contract_periods
          ContractPeriod.most_recent_first
        end

        def selected_contract_period
          @selected_contract_period ||= ContractPeriod.find_by(
            year: state_store.contract_period_year
          )
        end

        def selected_contract_period_label
          [
            selected_framework_agreement&.contract_period_year,
            selected_contract_period&.year,
            state_store.contract_period_year
          ].compact.first&.to_s
        end

        def framework_agreements
          FrameworkAgreement
            .for_contract_period_year(state_store.contract_period_year)
            .with_lead_provider_ordered_by_name
        end

        def selected_framework_agreement
          return if state_store.framework_agreement_id.blank?

          @selected_framework_agreement ||= FrameworkAgreement
            .includes(:lead_provider)
            .find_by(id: state_store.framework_agreement_id)
        end

        def selected_lead_provider
          selected_framework_agreement&.lead_provider
        end

        def delivery_partners
          selected_framework_agreement&.delivery_partners&.order(:name) ||
            DeliveryPartner.none
        end

        def selected_delivery_partner
          return if state_store.delivery_partner_id.blank?

          @selected_delivery_partner ||= DeliveryPartner.find_by(
            id: state_store.delivery_partner_id
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
