module Schools
  module InductionTutor
    class CheckAnswersStep < InductionTutor::Step
      def previous_step = :edit

      def next_step = :confirmation

      def save!
        ActiveRecord::Base.transaction do
          old_induction_tutor_name = school.induction_tutor_name
          assign_induction_tutor_attributes
          school.save!
          record_event!(old_induction_tutor_name)
        end

        send_confirmation_email!
        true
      end

    private

      def assign_induction_tutor_attributes
        school.induction_tutor_name = store.induction_tutor_name
        school.induction_tutor_email = store.induction_tutor_email
        if closest_contract_period.present?
          school.induction_tutor_last_nominated_in = closest_contract_period
        end
      end

      def send_confirmation_email!
        return unless wizard.send_confirmation_email?

        Schools::InductionTutorConfirmationMailer.with(school:).confirmation.deliver_later
      end

      def record_event!(old_induction_tutor_name)
        Events::Record.record_school_induction_tutor_updated_event!(
          school:,
          old_name: old_induction_tutor_name,
          new_name: store.induction_tutor_name,
          new_email: store.induction_tutor_email,
          contract_period_year: closest_contract_period&.year,
          author:
        )
      end

      def pre_populate_attributes = nil
    end
  end
end
