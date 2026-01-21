module ECTAtSchoolPeriods
  class Finish
    attr_reader :ect_at_school_period, :finished_on, :author, :reported_by_school_id

    def initialize(ect_at_school_period:, finished_on:, author:, reported_by_school_id: nil)
      @ect_at_school_period = ect_at_school_period
      @finished_on = finished_on
      @author = author
      @reported_by_school_id = reported_by_school_id
    end

    def finish!
      ActiveRecord::Base.transaction do
        finish_ect_at_school_period!
        finish_mentorship_periods!
        finish_training_period!
      end
    end

  private

    def finish_ect_at_school_period!
      if ect_at_school_period.finished_on.present? && ect_at_school_period.finished_on <= finished_on
        update_reporting_school!
        return
      end

      ect_at_school_period.update!(finish_attrs)

      Events::Record.record_teacher_left_school_as_ect!(
        author:,
        ect_at_school_period:,
        happened_at: finished_on,
        **event_params
      )
    end

    def update_reporting_school!
      return unless reported_by_school_id

      ect_at_school_period.update!(reported_leaving_by_school_id: reported_by_school_id)
    end

    def finish_mentorship_periods!
      destroy_unstarted_mentorship_periods!

      return unless (
        mentorship_period = ect_at_school_period.mentorship_periods
                                                .find_by(MentorshipPeriod.date_in_range(finished_on))
      )

      return if mentorship_period.finished_on.present? && mentorship_period.finished_on <= finished_on

      MentorshipPeriods::Finish.new(author:, mentorship_period:, finished_on:).finish!
    end

    def finish_training_period!
      destroy_unstarted_training_periods!

      return unless (
        training_period = ect_at_school_period.training_periods
                                              .find_by(TrainingPeriod.date_in_range(finished_on))
      )

      return if training_period.finished_on.present? && training_period.finished_on <= finished_on

      TrainingPeriods::Finish.ect_training(author:, training_period:, ect_at_school_period:, finished_on:).finish!
    end

    def training_period
      @training_period ||= ect_at_school_period.current_or_next_training_period
    end

    def destroy_unstarted_training_periods!
      ect_at_school_period.training_periods.started_on_or_after(finished_on).find_each do |training_period|
        Event.where(training_period:).delete_all
        training_period.destroy!
      end
    end

    def destroy_unstarted_mentorship_periods!
      ect_at_school_period.mentorship_periods.started_on_or_after(finished_on).find_each do |mentorship_period|
        Event.where(mentorship_period:).delete_all
        mentorship_period.destroy!
      end
    end

    def event_params
      {
        teacher: ect_at_school_period.teacher,
        school: ect_at_school_period.school,
        training_period: ect_at_school_period.current_or_next_training_period
      }
    end

    def finish_attrs
      { finished_on: }.tap do |attrs|
        attrs[:reported_leaving_by_school_id] = reported_by_school_id if reported_by_school_id
      end
    end
  end
end
