module Schools
  module Mentors
    module ChangeEmailAddressWizard
      class CheckAnswersStep < Step
        def previous_step = :edit
        def next_step = :confirmation

        def current_email = mentor_at_school_period.email
        def new_email = store.email

        def save!
          ApplicationRecord.transaction do
            old_email = current_email
            mentor_at_school_period.update!(email: new_email)
            Events::Record.record_teacher_email_updated_event!(
              old_email:,
              new_email:,
              author:,
              mentor_at_school_period:,
              school: mentor_at_school_period.school,
              teacher: mentor_at_school_period.teacher,
              happened_at: Time.current
            )
            true
          end
        end
      end
    end
  end
end
