module Schools
  module Mentors
    module ChangeNameWizard
      class Wizard
        include DfE::Wizard

        def self.routes = %i[edit confirm_name_change check_answers confirmation]

        def steps_processor
          DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: self) do |graph|
            graph.add_node :edit, Steps::EditStep
            graph.add_node :confirm_name_change, Steps::ConfirmNameChangeStep
            graph.add_node :check_answers, Steps::CheckAnswersStep
            graph.add_node :confirmation, Steps::ConfirmationStep

            graph.root :edit

            graph.add_conditional_edge from: :edit,
                                       when: :significant_name_change?,
                                       then: :confirm_name_change,
                                       else: :check_answers
            graph.add_edge from: :confirm_name_change, to: :check_answers
            graph.add_edge from: :check_answers, to: :confirmation
          end
        end

        def steps_operator
          DfE::Wizard::StepsOperator::Builder.draw(wizard: self, callable: state_store) do |builder|
            builder.on_step(:check_answers, use: [Operations::UpdateName])
          end
        end

        def route_strategy
          DfE::Wizard::RouteStrategy::ConfigurableRoutes.new(
            wizard: self,
            namespace: "schools_mentors_change_name_wizard"
          ) do |routes|
            routes.default_path_arguments = { mentor_id: mentor_at_school_period.id }
          end
        end

        delegate :mentor_at_school_period, to: :state_store
        delegate :teacher, to: :mentor_at_school_period

        def teacher_full_name
          ::Teachers::Name.new(mentor_at_school_period.teacher.reload).full_name
        end

        def details_path
          Rails.application.routes.url_helpers.schools_mentor_path(mentor_at_school_period)
        end

        def mentor? = true

        def significant_name_change?
          ::Teachers::NameChange.new(teacher_full_name, state_store.name).significant?
        end

        def furthest_valid_step_path
          step_id = root_step
          while valid?(step_id) && (next_step_id = steps_processor.next_step(step_id))
            step_id = next_step_id
          end

          resolve_step_path(step_id)
        end

        def author = Current.user
      end
    end
  end
end
