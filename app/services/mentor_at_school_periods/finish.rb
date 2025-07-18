class MentorAtSchoolPeriods::Finish
  attr_reader :teacher, :finished_on

  def initialize(teacher:, finished_on:)
    @teacher = teacher
    @finished_on = finished_on
  end

  def finish_existing_at_school_periods!
    ActiveRecord::Base.transaction do
      teacher.mentor_at_school_periods.ongoing_on(finished_on).each do |period|
        period.update!(finished_on:)
        period.mentorship_periods.ongoing_on(finished_on).update!(finished_on:)
        period.training_periods.ongoing_on(finished_on).update!(finished_on:)
      end
    end
  end
end
