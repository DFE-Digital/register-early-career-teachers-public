class ECF2TeacherHistory::MentorAtSchoolPeriodRow
  attr_reader :started_on,
              :finished_on,
              :school,
              :email,
              :training_period_rows,
              :import_note

  def initialize(started_on:, finished_on:, school:, email:, training_period_rows: [], import_note: nil)
    @started_on = started_on
    @finished_on = finished_on
    @school = school
    @email = email
    @training_period_rows = training_period_rows
    @import_note = import_note
  end

  def to_hash
    {
      started_on:,
      finished_on:,
      school: real_school,
      email:
    }
  end

  def real_school
    GIAS::School.find_by!(urn: school.urn).school
  end
end
