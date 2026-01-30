module ECTAtSchoolPeriods
  class Destroy
    attr_reader :ect_at_school_period, :author

    def initialize(ect_at_school_period:, author:)
      @ect_at_school_period = ect_at_school_period
      @author = author
    end

    def self.call(**args)
      new(**args).call
    end

    def call
      return unless ect_at_school_period
      return if ect_at_school_period_started?

      ActiveRecord::Base.transaction do
        record_unstarted_ect_period_deleted_event!
        destroy_mentorship_period_events!
        destroy_training_period_events!
        destroy_ect_at_school_period_events!
        ect_at_school_period.destroy!
      end
    end

  private

    def destroy_mentorship_period_events!
      mentorship_periods.each do |mentorship_period|
        mentorship_period.events.each(&:destroy!)
      end
    end

    def destroy_training_period_events!
      training_periods.each do |training_period|
        training_period.events.each(&:destroy!)
      end
    end

    def mentorship_periods
      ect_at_school_period.mentorship_periods
    end

    def training_periods
      ect_at_school_period.training_periods
    end

    def destroy_ect_at_school_period_events!
      ect_at_school_period.events.each(&:destroy!)
    end

    def record_unstarted_ect_period_deleted_event!
      Events::Record.record_teacher_ect_at_school_period_deleted!(author:, teacher:, school:, started_on:)
    end

    def teacher
      ect_at_school_period.teacher
    end

    def school
      ect_at_school_period.school
    end

    def ect_at_school_period_started?
      started_on < Time.zone.today
    end

    def started_on
      ect_at_school_period.started_on
    end
  end
end
