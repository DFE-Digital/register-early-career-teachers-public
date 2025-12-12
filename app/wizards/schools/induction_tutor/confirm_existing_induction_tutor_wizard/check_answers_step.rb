module Schools
  module InductionTutor
    module ConfirmExistingInductionTutorWizard
      class CheckAnswersStep < ApplicationWizardStep
        delegate :school, :author, :valid_step?, :current_contract_period, to: :wizard

        def self.permitted_params = []

        def previous_step = :edit

        def next_step = :confirmation

        def save!
          ActiveRecord::Base.transaction do
            record_event!

            school.update!(
              induction_tutor_name: store.induction_tutor_name,
              induction_tutor_email: store.induction_tutor_email,
              induction_tutor_last_nominated_in: current_contract_period
            )
            true
          end
        end

      private

        def record_event!
          Events::Record.record_school_induction_tutor_updated_event!(
            school:,
            old_name: school.induction_tutor_name,
            new_name: store.induction_tutor_name,
            new_email: store.induction_tutor_email,
            contract_period_year: current_contract_period.year,
            author:
          )
        end

        def pre_populate_attributes = nil
      end
    end
  end
end
