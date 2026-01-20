module Schools
  module InductionTutor
    class CheckAnswersStep < InductionTutor::Step
      def previous_step = :edit

      def next_step = :confirmation

      def save!
        old_email = school.induction_tutor_email
        old_name = school.induction_tutor_name

        ActiveRecord::Base.transaction do
          record_event!

          school.update!(
            induction_tutor_name: store.induction_tutor_name,
            induction_tutor_email: store.induction_tutor_email,
            induction_tutor_last_nominated_in: current_contract_period
          )
          true
        end

        send_confirmation_email_if_details_different!(old_email:, old_name:)
      end

    private

      def send_confirmation_email_if_details_different!(old_email:, old_name:)
        return if details_unchanged?(old_email:, old_name:)

        Schools::InductionTutorConfirmationMailer.with(school:).confirmation.deliver_later
      end

      def details_unchanged?(old_email:, old_name:)
        old_email == school.induction_tutor_email && old_name == school.induction_tutor_name
      end

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
