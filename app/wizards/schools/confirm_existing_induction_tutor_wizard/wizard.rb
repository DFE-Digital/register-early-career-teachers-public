module Schools
  module ConfirmExistingInductionTutorWizard
    class Wizard < ApplicationWizard
      attr_accessor :store, :school, :school_id, :author

      steps do
        [{
          edit: EditStep,
          check_answers: CheckAnswersStep,
          confirmation: ConfirmationStep
        }]
      end

      def allowed_steps = %i[edit check_answers confirmation]

      def self.step?(step_name)
        Array(steps).first[step_name].present?
      end

      # @return [Hash]
      def default_path_arguments
        { school_id: school.id }
      end

      def school
        @school ||= School.find(school_id)
      end

      delegate :save!, to: :current_step
      delegate :reset, to: :store

      # def route_name
      #   "school_induction_confirm_existing_induction_tutor_wizard"
      # end
    end
  end
end
