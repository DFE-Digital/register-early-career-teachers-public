module Schools::AssignExistingMentorWizard
  class Wizard
    include DfE::Wizard

    def self.routes = %i[review_mentor_eligibility lead_provider confirmation]

    def steps_processor
      DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
        graph.add_node :review_mentor_eligibility, Steps::ReviewMentorEligibilityStep
        graph.add_node :lead_provider, Steps::LeadProviderStep
        graph.add_node :confirmation, Steps::ConfirmationStep

        graph.root :review_mentor_eligibility

        graph.add_edge from: :review_mentor_eligibility, to: :confirmation
        graph.add_edge from: :lead_provider, to: :confirmation
      end
    end

    def steps_operator
      DfE::Wizard::StepsOperator::Builder.draw(wizard: self, callable: state_store) do |builder|
        builder.on_step(:review_mentor_eligibility, use: [Operations::AssignMentorWithTraining])
        builder.on_step(:lead_provider, add: [Operations::AssignMentorWithTraining])
      end
    end

    def route_strategy
      DfE::Wizard::RouteStrategy::NamedRoutes.new(wizard: self, namespace: "schools_assign_existing_mentor_wizard")
    end

    delegate :ect_at_school_period,
             :mentor_at_school_period,
             :ect_teacher_full_name,
             :mentor_teacher_full_name,
             :ect_lead_provider,
             :ect_lead_provider_available?,
             :lead_providers_within_contract_period,
             to: :state_store

    def author = Current.user
  end
end
