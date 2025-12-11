module Schools
  module NewInductionTutorWizard
    class Wizard < ApplicationWizard
      attr_accessor :store, :school_id,
                    :induction_tutor_email, :induction_tutor_name,
                    :are_these_details_correct,
                    :author

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

      def school
        @school ||= School.find(school_id)
      end

      def current_contract_period
        ContractPeriod.current
      end

      delegate :save!, to: :current_step
      delegate :reset, to: :store
    end
  end
end
