class ECF2TeacherHistory::ECTAtSchoolPeriodRow
  attr_reader :started_on,
              :finished_on,
              :school,
              :email,
              :appropriate_body,
              :mentorship_period_rows,
              :training_period_rows

  def initialize(started_on:, finished_on:, school:, email:, mentorship_period_rows:, training_period_rows:, appropriate_body: nil)
    @started_on = started_on
    @finished_on = finished_on
    @school = school
    @email = email
    @appropriate_body = appropriate_body
    @mentorship_period_rows = mentorship_period_rows
    @training_period_rows = training_period_rows
  end

  def to_hash
    {
      started_on:,
      finished_on:,
      school: real_school,
      email:,
      school_reported_appropriate_body: real_appropriate_body,
    }
  end

  def to_h
    {
      started_on:,
      finished_on:,
      school:,
      email:,
      school_reported_appropriate_body: appropriate_body,
      training_periods: training_period_rows.map(&:to_h)
    }
  end

  def real_school
    GIAS::School.find_by!(urn: school.urn).school
  end

  def real_appropriate_body
    # AppropriateBody.find(appropriate_body.id)
  end
end
