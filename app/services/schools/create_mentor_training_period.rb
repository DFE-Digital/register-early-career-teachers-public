module Schools
  class CreateMentorTrainingPeriod
    include TrainingPeriodSources

    attr_reader :mentor_at_school_period, :lead_provider, :started_on, :author

    def initialize(mentor_at_school_period:, lead_provider:, author:, started_on:)
      @mentor_at_school_period = mentor_at_school_period
      @lead_provider = lead_provider
      @started_on = started_on
      @author = author
    end

    def create!
      ActiveRecord::Base.transaction do
        training_period = TrainingPeriods::Create.provider_led(
          period: mentor_at_school_period,
          started_on:,
          school_partnership: earliest_matching_school_partnership,
          expression_of_interest:
        ).call

        record_training_period_event!(training_period)
        training_period
      end
    end

  private

    def school
      mentor_at_school_period.school
    end

    def record_training_period_event!(training_period)
      Events::Record.record_teacher_starts_training_period_event!(
        author:,
        teacher: mentor_at_school_period.teacher,
        school:,
        training_period:,
        mentor_at_school_period:,
        ect_at_school_period: nil,
        happened_at: started_on
      )
    end
  end
end
