class MentorAtSchoolPeriods::Finish
  attr_reader :teacher, :finished_on, :author, :reported_by_school_id

  def initialize(teacher:, finished_on:, author:, reported_by_school_id: nil)
    @teacher = teacher
    @finished_on = finished_on
    @author = author
    @reported_by_school_id = reported_by_school_id
  end

  def finish_existing_at_school_periods!
    ActiveRecord::Base.transaction do
      teacher.mentor_at_school_periods.ongoing_on(finished_on).each do |period|
        finish_mentorship_periods!(period)
        finish_training_periods!(period)
        finish_mentor_at_school_period!(period)
        record_mentor_left_school_event!(period)
      end
    end
  end

private

  def finish_mentorship_periods!(period)
    destroy_unstarted_mentorship_periods!(period)

    period.mentorship_periods.ongoing_on(finished_on).each do |mentorship_period|
      MentorshipPeriods::Finish.new(mentorship_period:, finished_on:, author:).finish!
    end
  end

  def destroy_unstarted_mentorship_periods!(period)
    period.mentorship_periods.started_on_or_after(finished_on).find_each do |mentorship_period|
      Event.where(mentorship_period:).delete_all
      mentorship_period.destroy!
    end
  end

  def finish_training_periods!(period)
    period.training_periods.ongoing_on(finished_on).each do |training_period|
      TrainingPeriods::Finish.mentor_training(training_period:, mentor_at_school_period: period, finished_on:, author:).finish!
    end
  end

  def finish_mentor_at_school_period!(period)
    if period.finished_on.present? && period.finished_on <= finished_on
      update_reporting_school!(period)
      return
    end

    period.update!(finish_attrs)
  end

  def update_reporting_school!(period)
    return unless reported_by_school_id

    period.update!(reported_leaving_by_school_id: reported_by_school_id)
  end

  def record_mentor_left_school_event!(period)
    Events::Record.record_teacher_left_school_as_mentor!(
      author:,
      mentor_at_school_period: period,
      teacher:,
      school: period.school,
      happened_at: finished_on
    )
  end

  def finish_attrs
    { finished_on: }.tap do |attrs|
      attrs[:reported_leaving_by_school_id] = reported_by_school_id if reported_by_school_id
    end
  end
end
