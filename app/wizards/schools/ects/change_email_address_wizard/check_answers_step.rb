module Schools
  module ECTs
    module ChangeEmailAddressWizard
      class CheckAnswersStep < BaseStep
        def previous_step = :edit
        def next_step = :confirmation

        def current_email = ect_at_school_period.email
        def new_email = store.email

        def save!
          ApplicationRecord.transaction do
            old_email = current_email
            ect_at_school_period.update!(email: new_email)
            Events::Record.record_teacher_email_updated_event!(
              old_email:,
              new_email:,
              author:,
              ect_at_school_period:,
              school: ect_at_school_period.school,
              teacher: ect_at_school_period.teacher,
              happened_at: Time.current
            )
            true
          end
        end
      end
    end
  end
end
