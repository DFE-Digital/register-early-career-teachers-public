module Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard
  class Wizard
    include DfE::Wizard

    def self.routes = %i[select_contract_period select_partnership no_partnerships check_answers]

    def steps_processor
      DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
        graph.add_node :select_contract_period, Steps::SelectContractPeriodStep
        graph.add_node :select_partnership, Steps::SelectPartnershipStep
        graph.add_node :no_partnerships, Steps::NoPartnershipsStep
        graph.add_node :check_answers, Steps::CheckAnswersStep

        graph.root :select_contract_period

        graph.add_multiple_conditional_edges(
          from: :select_contract_period,
          branches: [
            { when: :training_period_eoi_only?, then: :check_answers },
            { when: :no_school_partnerships?, then: :no_partnerships },
            { when: :multiple_school_partnerships?, then: :select_partnership }
          ],
          default: :check_answers
        )
        graph.add_edge from: :select_partnership, to: :check_answers
      end
    end

    def steps_operator
      DfE::Wizard::StepsOperator::Builder.draw(wizard: self, callable: state_store) do |builder|
        builder.on_step(:select_contract_period, add: [Operations::ResetSchoolPartnershipSelection])
        builder.on_step(:check_answers, use: [Operations::ApplyContractPeriodChange])
      end
    end

    def route_strategy
      DfE::Wizard::RouteStrategy::ConfigurableRoutes.new(
        wizard: self,
        namespace: "admin_teacher_training_period_change_contract_period_wizard"
      ) do |routes|
        routes.default_path_arguments = {
          teacher_id: training_period.teacher_id,
          training_period_id: training_period.id
        }
      end
    end

    delegate :training_period,
             :school,
             :teacher_name,
             :training_period_eoi_only?,
             :contract_periods,
             :existing_contract_period,
             :selected_contract_period,
             :partnership_options,
             :selected_partnership_name,
             :selected_lead_provider_name,
             to: :state_store

    def author = Current.user

    def furthest_valid_step_path
      step_id = root_step
      while valid?(step_id) && (next_step_id = steps_processor.next_step(step_id))
        step_id = next_step_id
      end

      resolve_step_path(step_id)
    end
  end
end
