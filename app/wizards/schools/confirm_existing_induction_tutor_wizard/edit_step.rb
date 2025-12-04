module Schools
  module ConfirmExistingInductionTutorWizard
    class EditStep < ApplicationWizardStep
      delegate :school, :author, :valid_step?, :current_contract_period, to: :wizard

      attribute :induction_tutor_email, :string
      attribute :induction_tutor_name, :string
      attribute :are_these_details_correct, :boolean

      validates :induction_tutor_email, notify_email: true, allow_blank: true

      validates :induction_tutor_email,
                presence: { message: "Enter an email address" },
                length: { maximum: 254, message: "Enter an email address that is less than 254 characters long" }, unless: :are_these_details_correct

      validates :induction_tutor_name,
                presence: { message: "Enter the correct full name" },
                length: { maximum: 70, message: "Full name must be 70 letters or less" }, unless: :are_these_details_correct

      validates :are_these_details_correct,
                inclusion: { in: [true, false], message: "Select 'Yes' or 'No, someone else will be the induction tutor'" }

      validate :details_must_be_changed_unless_confirmed

      def self.permitted_params = %i[
        induction_tutor_name
        induction_tutor_email
        are_these_details_correct
      ]

      def next_step
        if are_these_details_correct
          :confirmation
        else
          :check_answers
        end
      end

      def save!
        if are_these_details_correct
          store.are_these_details_correct = are_these_details_correct

          ActiveRecord::Base.transaction do
            school.update!(induction_tutor_last_nominated_in: current_contract_period)

            record_confirmation_event!
          end
        else
          add_data_to_store
        end
      end

    private

      def pre_populate_attributes
        self.induction_tutor_email = store.induction_tutor_email.presence || school.induction_tutor_email
        self.induction_tutor_name = store.induction_tutor_name.presence || school.induction_tutor_name
      end

      def add_data_to_store
        return unless valid_step?

        store.induction_tutor_email = induction_tutor_email
        store.induction_tutor_name = induction_tutor_name
        store.are_these_details_correct = are_these_details_correct
      end

      def record_confirmation_event!
        Events::Record.record_school_induction_tutor_confirmed_event!(
          school:,
          name: school.induction_tutor_name,
          email: school.induction_tutor_email,
          contract_period_year: current_contract_period.year,
          author:
        )
      end

      def details_must_be_changed_unless_confirmed
        return if are_these_details_correct

        if induction_tutor_email == school.induction_tutor_email &&
            induction_tutor_name == school.induction_tutor_name
          errors.add(:base, "You must change the induction tutor details or confirm they are correct")
        end
      end
    end
  end
end
