module Teachers
  class ChangeSchedule
    attr_reader :lead_provider, :teacher, :training_period, :schedule, :school_partnership

    def initialize(lead_provider:, teacher:, training_period:, schedule:, school_partnership:)
      @lead_provider = lead_provider
      @teacher = teacher
      @training_period = training_period
      @schedule = schedule
      @school_partnership = school_partnership
    end

    def change_schedule
      ActiveRecord::Base.transaction do
        finish_training_period!

        new_training_period = TrainingPeriods::Create.provider_led(
          period: training_period.trainee,
          started_on: [training_period.finished_on, Time.zone.today].compact.max,
          finished_on: training_period.trainee.finished_on,
          school_partnership:,
          expression_of_interest: nil,
          schedule:
        ).call

        record_change_schedule_event!(new_training_period)
      end

      teacher
    end

  private

    def finish_training_period!
      return if training_period.finished_on

      if training_period.for_ect?
        TrainingPeriods::Finish.ect_training(
          author:,
          training_period:,
          ect_at_school_period: training_period.trainee,
          finished_on: Time.zone.today
        ).finish!
      elsif training_period.for_mentor?
        TrainingPeriods::Finish.mentor_training(
          author:,
          training_period:,
          mentor_at_school_period: training_period.trainee,
          finished_on: Time.zone.today
        ).finish!
      end
    end

    def record_change_schedule_event!(new_training_period)
      return unless new_training_period.saved_changes?

      Events::Record.record_teacher_training_period_change_schedule_event!(
        author:,
        training_period:,
        teacher:,
        lead_provider:,
        metadata: { new_training_period_id: new_training_period.id }
      )
    end

    def author
      @author ||= Events::LeadProviderAPIAuthor.new(lead_provider:)
    end
  end
end
