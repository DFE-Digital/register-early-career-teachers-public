module ECTAtSchoolPeriods
  class ChangeStartDate
    def self.change(...) = new(...).change

    def initialize(ect_at_school_period, started_on:, author:)
      raise ArgumentError, "an `ECTAtSchoolPeriod` must be provided" unless
        ect_at_school_period.is_a?(ECTAtSchoolPeriod)

      @ect_at_school_period = ect_at_school_period
      @training_period = ect_at_school_period.latest_training_period
      @mentorship_period = ect_at_school_period.latest_mentorship_period
      @original_started_on = ect_at_school_period.started_on
      @started_on = started_on
      @author = author
    end

    def change
      ActiveRecord::Base.transaction do
        if moving_start_date_earlier?
          move_start_date_earlier!
        else
          move_start_date_later!
        end

        record_event!
      end
    end

  private

    attr_reader :ect_at_school_period,
                :training_period,
                :mentorship_period,
                :original_started_on,
                :started_on,
                :author

    def move_start_date_earlier!
      update_ect_at_school_period!
      update_training_period!
      update_mentorship_period!
    end

    def move_start_date_later!
      update_training_period!
      update_mentorship_period!
      update_ect_at_school_period!
    end

    def update_ect_at_school_period!
      ect_at_school_period.update!(started_on:)
    end

    def update_training_period!
      training_period.update!(
        started_on: training_period_started_on
      )
    end

    def update_mentorship_period!
      return unless mentorship_period

      if new_start_date_invalidates_mentorship_period?
        mentorship_period.destroy!
      else
        mentorship_period.update!(
          started_on: mentorship_period_started_on
        )
      end
    end

    def new_start_date_invalidates_mentorship_period?
      mentorship_period.finished_on.present? &&
        started_on >= mentorship_period.finished_on
    end

    def training_period_started_on
      return started_on unless moving_start_date_earlier?

      [started_on, Date.current].max
    end

    def mentorship_period_started_on
      [
        started_on,
        mentorship_period.mentor.started_on
      ].max
    end

    def moving_start_date_earlier?
      started_on < original_started_on
    end

    def record_event!
      Events::Record.record_teacher_school_start_date_updated_event!(
        old_start_date: original_started_on,
        new_start_date: started_on,
        author:,
        ect_at_school_period:,
        school: ect_at_school_period.school,
        teacher: ect_at_school_period.teacher,
        happened_at: Time.zone.now
      )
    end
  end
end
