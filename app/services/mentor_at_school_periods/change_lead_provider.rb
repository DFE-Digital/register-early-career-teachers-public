module MentorAtSchoolPeriods
  class ChangeLeadProvider
    attr_reader :mentor_at_school_period,
                :school_partnership,
                :author

    def initialize(mentor_at_school_period:, school_partnership:, author:)
      @mentor_at_school_period = mentor_at_school_period
      @school_partnership = school_partnership
      @author = author
    end

    def call
      # TODO: do something
      # Hints
      # Close the existing training training_periods
      # Open a new training period linked to the new lead provider
      # Write some events

      finish_existing_at_school_periods!
      create_new_training_period

      # TrainingPeriods.create(period: @mentor_at_school_period, started_on:, training_programme:, school_partnership: nil, expression_of_interest: nil)
    end

    def finish_existing_at_school_periods!
      ActiveRecord::Base.transaction do
        teacher.mentor_at_school_periods.ongoing_on(finished_on).each do |period|
          finish_mentorship_periods!(period)
          finish_training_periods!(period)
        end
      end
    end

    def create_new_training_period
      ActiveRecord::Base.transaction do
        TrainingPeriods::Create.new(
          period: mentor_at_school_period,
          started_on:,
          school_partnership:,
          training_programme: 'provider_led'
        ).call
      end
    end

  private

    def finish_mentorship_periods!(period)
      period.mentorship_periods.ongoing_on(finished_on).each do |mentorship_period|
        MentorshipPeriods::Finish.new(mentorship_period:, finished_on:, author:).finish!
      end
    end

    def finish_training_periods!(period)
      period.training_periods.ongoing_on(finished_on).each do |training_period|
        TrainingPeriods::Finish.mentor_training(training_period:, mentor_at_school_period: period, finished_on:, author:).finish!
      end
    end

    def training_periods
      mentor_at_school_period.training_periods.ongoing
    end

    # TODO: dates
    def finished_on
      Time.zone.today
    end

    def started_on
      finished_on + 1
    end

    def teacher
      mentor_at_school_period.teacher
    end

    def ect_at_school_period
      ect_at_school_period
    end
  end
end
