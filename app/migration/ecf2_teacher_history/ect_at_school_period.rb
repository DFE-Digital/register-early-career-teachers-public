class ECF2TeacherHistory::ECTAtSchoolPeriod
  attr_reader :started_on,
              :finished_on,
              :school,
              :email,
              :appropriate_body,
              :mentorship_periods,
              :training_periods

  def initialize(started_on:,
                 finished_on:,
                 school:, email:,
                 mentorship_periods:,
                 training_periods:,
                 appropriate_body: nil)
    @started_on = started_on
    @finished_on = finished_on
    @school = school
    @email = email
    @appropriate_body = appropriate_body
    @mentorship_periods = mentorship_periods
    @training_periods = training_periods
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
      school: school.to_h,
      email:,
      school_reported_appropriate_body: appropriate_body,
      mentorship_periods: mentorship_periods.map(&:to_h),
      training_periods: training_periods.map(&:to_h),
    }
  end

  # if we update a ect_at_school_period's finished_on after creation
  # we need to adjust any training_period that matches it too
  def finished_on=(date)
    original_finished_on = @finished_on

    @finished_on = date

    training_periods.select { it.finished_on == original_finished_on }
                    .each { |tp| tp.finished_on = date }
  end

  def real_school
    GIAS::School.find_by!(urn: school.urn).school
  end

  def real_appropriate_body
    # AppropriateBody.find(appropriate_body.id)
  end

  def dates
    [started_on, finished_on]
  end

  def range
    started_on..finished_on
  end

  def ongoing?
    finished_on.nil?
  end
end
