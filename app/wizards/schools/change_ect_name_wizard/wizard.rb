module Schools
  module ChangeECTNameWizard
    class Wizard < ApplicationWizard
      attr_accessor :store, :ect_id, :author

      steps do
        [
          {
            edit: EditStep,
            check_answers: CheckAnswersStep,
            confirmation: ConfirmationStep,
          }
        ]
      end

      def self.step?(step_name)
        Array(steps).first[step_name].present?
      end

      def ect_at_school_period
        @ect_at_school_period ||= ECTAtSchoolPeriod.find(ect_id)
      end

      def full_name
        Teachers::Name.new(ect_at_school_period.teacher).full_name
      end

      def previous_step_path
        custom_step_path(current_step.previous_step)
      end

      def current_step_path
        custom_step_path(current_step.step_name.underscore)
      end

      def next_step_path
        custom_step_path(current_step.next_step)
      end

    private

      # Avoid additional namespacing and pass in params
      # @param step_name [Symbol]
      # @return [String]
      def custom_step_path(step_name)
        url_helpers.public_send("schools_ect_change_name_#{step_name}_path", { ect_id: })
      end
    end
  end
end
