class ECF2TeacherHistory::MentorAtSchoolPeriod
  attr_reader :started_on,
              :finished_on,
              :school,
              :email,
              :training_periods

  def initialize(started_on:, finished_on:, school:, email:, training_periods: [])
    @started_on = started_on
    @finished_on = finished_on
    @school = school
    @email = email
    @training_periods = training_periods
  end

  def to_hash
    {
      started_on:,
      finished_on:,
      school: real_school,
      email:
    }
  end

  def to_h
    {
      started_on:,
      finished_on:,
      school:,
      email:,
      training_periods: training_periods.map(&:to_h)
    }
  end

  def real_school
    GIAS::School.find_by!(urn: school.urn).school
  end
end
