module Schools
  module ConfirmExistingInductionTutorWizard
    class CheckAnswersStep < Step
      def previous_step = :edit

      def next_step = :confirmation

      def save!
        ActiveRecord::Base.transaction do
          school.update!(
            induction_tutor_name: store.induction_tutor_name,
            induction_tutor_email: store.induction_tutor_email
          )
          true
        end
      end
    end
  end
end
