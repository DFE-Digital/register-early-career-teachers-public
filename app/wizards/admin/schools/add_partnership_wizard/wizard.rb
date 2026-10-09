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

        attr_reader :author

        delegate :school,
                 :contract_periods,
                 :selected_contract_period,
                 :selected_contract_period_label,
                 :framework_agreements,
                 :selected_framework_agreement,
                 :selected_lead_provider,
                 :delivery_partners,
                 :selected_delivery_partner,
                 :lead_provider_delivery_partnership,
                 to: :state_store

        def initialize(author:, state_store:, current_step:, current_step_params: {})
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
              :check_answers,
              use: [Operations::CreatePartnership]
            )
          end
        end

        def route_strategy
          DfE::Wizard::RouteStrategy::ConfigurableRoutes.new(
            wizard: self,
            namespace: :admin_schools_add_partnership_wizard
          ) do |routes|
            routes.default_path_arguments = { school_urn: school.urn }
          end
        end

        def furthest_valid_step_path
          step_id = root_step

          while valid?(step_id) && (next_step_id = steps_processor.next_step(step_id))
            step_id = next_step_id
          end

          resolve_step_path(step_id)
        end
      end
    end
  end
end
