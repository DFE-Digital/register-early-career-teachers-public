module Schools
  module ConfirmExistingInductionTutorWizard
    class CheckAnswersStep < ApplicationWizardStep
      delegate :school, :author, :valid_step?, :current_contract_period, to: :wizard

      def self.permitted_params = []

      def previous_step = :edit

      def next_step = :confirmation

      def save!
        ActiveRecord::Base.transaction do
          school.update!(
            induction_tutor_name: store.induction_tutor_name,
            induction_tutor_email: store.induction_tutor_email,
            induction_tutor_last_nominated_in_year: current_contract_period
          )
          true
        end
      end

    private

      def pre_populate_attributes = nil
    end
  end
end
