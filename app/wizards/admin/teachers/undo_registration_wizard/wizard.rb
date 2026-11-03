module Admin::Teachers::UndoRegistrationWizard
  class Wizard
    include DfE::Wizard

    def self.routes = %i[start select_school_period confirm confirmation]

    def steps_processor
      DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
        graph.add_node :start, Steps::StartStep
        graph.add_node :select_school_period, Steps::SelectSchoolPeriodStep
        graph.add_node :confirm, Steps::ConfirmStep
        graph.add_node :confirmation, Steps::ConfirmationStep

        graph.root :start
        graph.add_conditional_edge(
          from: :start,
          when: :multiple_school_periods?,
          then: :select_school_period,
          else: :confirm
        )
        graph.add_edge from: :select_school_period, to: :confirm
        graph.add_edge from: :confirm, to: :confirmation
      end
    end

    def steps_operator
      DfE::Wizard::StepsOperator::Builder.draw(wizard: self, callable: state_store) do |builder|
        builder.on_step(:confirm, use: [DfE::Wizard::Operations::Validate, Operations::UndoRegistration])
      end
    end

    def route_strategy
      DfE::Wizard::RouteStrategy::ConfigurableRoutes.new(
        wizard: self,
        namespace: "admin_teacher_undo_registration_wizard"
      ) do |routes|
        routes.default_path_arguments = { teacher_id: teacher.id }
      end
    end

    delegate :teacher,
             :teacher_name,
             :ect_at_school_periods,
             :mentor_at_school_periods,
             :at_school_periods,
             :at_school_period,
             :at_school_period_from_gid,
             :periods_will_be_closed?,
             :finish_date_for,
             :affected_training_periods,
             :affected_mentorship_periods,
             :undo_action,
             :registration_undone?,
             :journey_available?,
             to: :state_store

    def furthest_valid_step_path
      step_id = root_step
      while valid?(step_id) && (next_step_id = steps_processor.next_step(step_id))
        step_id = next_step_id
      end

      resolve_step_path(step_id)
    end
  end
end
