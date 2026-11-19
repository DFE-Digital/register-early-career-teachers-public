module Schools::Mentors::ChangeEmailAddressWizard::Operations
  class UpdateEmail
    def initialize(repository:, step:)
      @repository = repository
      @step = step
    end

    def execute
      ApplicationRecord.transaction do
        old_email = mentor_at_school_period.email

        state_store.write(original_email: old_email)
        mentor_at_school_period.update!(email: new_email)
        record_event!(old_email)
      end

      { success: true }
    end

  private

    attr_reader :repository, :step

    delegate :wizard, to: :step
    delegate :state_store, :author, to: :wizard
    delegate :mentor_at_school_period, :email, to: :state_store

    alias_method :new_email, :email

    def record_event!(old_email)
      Events::Record.record_teacher_email_updated_event!(
        old_email:,
        new_email:,
        author:,
        mentor_at_school_period:,
        school: mentor_at_school_period.school,
        teacher: mentor_at_school_period.teacher,
        happened_at: Time.current
      )
    end
  end
end
