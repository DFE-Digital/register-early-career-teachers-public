module Schools
  module ConfirmExistingInductionTutorWizard
    class ConfirmationStep < ApplicationWizardStep
      delegate :school, :author, :valid_step?, to: :wizard

      def previous_step = :check_answers

      def new_induction_teacher_name = school.induction_tutor_name
      def new_induction_teacher_email = school.induction_tutor_email
    end
  end
end
