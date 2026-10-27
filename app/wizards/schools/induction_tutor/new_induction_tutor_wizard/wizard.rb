module Schools::InductionTutor::NewInductionTutorWizard
  class Wizard
    include DfE::Wizard

    def self.routes = %i[edit check_answers confirmation]

    def steps_processor
      DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
        graph.add_node :edit, Schools::InductionTutor::Steps::EditStep
        graph.add_node :check_answers, Schools::InductionTutor::Steps::CheckAnswersStep
        graph.add_node :confirmation, Schools::InductionTutor::Steps::ConfirmationStep

        graph.root :edit

        graph.add_edge from: :edit, to: :check_answers
        graph.add_edge from: :check_answers, to: :confirmation
      end
    end

    def steps_operator
      DfE::Wizard::StepsOperator::Builder.draw(wizard: self, callable: state_store) do |builder|
        builder.on_step(:check_answers, use: [Schools::InductionTutor::Operations::Update])
      end
    end

    def route_strategy
      DfE::Wizard::RouteStrategy::NamedRoutes.new(wizard: self, namespace: "schools_induction_tutor_new_induction_tutor_wizard")
    end

    delegate :school, :induction_tutor_name, :induction_tutor_email, to: :state_store

    def author = Current.user
  end
end
