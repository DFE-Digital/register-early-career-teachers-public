module Admin
  module DataFixesWizard
    class Wizard < ApplicationWizard
      steps do
        [
          {
            csv: CSVStep,
            preview: PreviewStep,
            # confirmation: ConfirmationStep
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

    private

      def step_path(step_name)
        url_helpers.public_send("admin_data_fixes_#{step_name}_path")
      end
    end
  end
end
