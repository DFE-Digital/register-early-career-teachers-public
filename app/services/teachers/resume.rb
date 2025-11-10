module Teachers
  class Resume
    attr_reader :author, :lead_provider, :teacher, :training_period

    def initialize(author:, lead_provider:, teacher:, training_period:)
      @author = author
      @lead_provider = lead_provider
      @teacher = teacher
      @training_period = training_period
    end

    def resume
      ActiveRecord::Base.transaction do
        new_training_period = TrainingPeriods::Create.provider_led(
          period: training_period.trainee,
          started_on: Time.zone.today,
          finished_on: training_period.trainee.finished_on,
          school_partnership: training_period.school_partnership,
          expression_of_interest: training_period.expression_of_interest,
          author:
        ).call

        record_resume_event!(new_training_period)
      end

      teacher
    end

  private

    def record_resume_event!(new_training_period)
      return if new_training_period.blank?

      Events::Record.record_teacher_training_period_resumed_event!(
        author:,
        training_period:,
        teacher:,
        lead_provider:,
        metadata: { new_training_period_id: new_training_period.id }
      )
    end
  end
end
