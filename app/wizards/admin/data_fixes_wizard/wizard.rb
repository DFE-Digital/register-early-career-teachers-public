module Admin::DataFixesWizard
  class Wizard
    include DfE::Wizard

    def self.routes = %i[csv preview verify confirmation]

    def steps_processor
      DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
        graph.add_node :csv, Steps::CSVStep
        graph.add_node :preview, Steps::PreviewStep
        graph.add_node :verify, Steps::VerifyStep
        graph.add_node :confirmation, Steps::ConfirmationStep

        graph.root :csv

        graph.add_edge from: :csv, to: :preview
        graph.add_edge from: :preview, to: :verify
        graph.add_edge from: :verify, to: :confirmation
      end
    end

    def steps_operator
      DfE::Wizard::StepsOperator::Builder.draw(wizard: self, callable: state_store) do |builder|
        builder.on_step(
          :csv,
          use: [
            DfE::Wizard::Operations::Validate,
            Operations::ParseCSV,
            DfE::Wizard::Operations::Persist
          ]
        )
        builder.on_step(
          :preview,
          use: [
            Operations::ProcessChanges,
            DfE::Wizard::Operations::Persist
          ]
        )
        builder.on_step(
          :verify,
          use: [
            DfE::Wizard::Operations::Validate,
            Operations::ConfirmChanges,
            DfE::Wizard::Operations::Persist
          ]
        )
      end
    end

    def route_strategy
      DfE::Wizard::RouteStrategy::NamedRoutes.new(wizard: self, namespace: "admin_data_fixes")
    end

    delegate :clear, to: :state_store

    def author = Current.user
    def error_presenter = ErrorSummaryPresenter

    class ErrorSummaryPresenter
      def initialize(error_messages)
        @error_messages = error_messages
      end

      def formatted_error_messages
        @error_messages.flat_map do |attribute, messages|
          messages.map { |message| [attribute, message] }
        end
      end
    end
  end
end
