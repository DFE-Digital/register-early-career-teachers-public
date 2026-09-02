module Admin
  module DataFixesWizard
    class Wizard < ApplicationWizard
      steps do
        [
          {
            csv: CSVStep,
            preview: PreviewStep,
            verify: VerifyStep,
            confirmation: ConfirmationStep
          }
        ]
      end

      def self.step?(step_name) = Array(steps).first[step_name].present?

      attr_accessor :store, :author

      delegate :save!, to: :current_step
      delegate :reset, to: :store

      def current_step_path = step_path(current_step_name)
      def next_step_path = step_path(current_step.next_step)
      def previous_step_path = step_path(current_step.previous_step)
      def error_presenter = ErrorSummaryPresenter

    private

      def step_path(step_name)
        url_helpers.public_send("admin_data_fixes_#{step_name}_path")
      end

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
end
