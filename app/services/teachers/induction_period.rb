class Teachers::InductionPeriod
  attr_reader :teacher

  def initialize(teacher)
    @teacher = teacher
  end

  def induction_start_date
    first_induction_period&.started_on
  end

  def formatted_induction_start_date
    induction_start_date&.to_fs(:govuk)
  end

  def induction_programme
    return unless first_induction_period

    ::INDUCTION_PROGRAMMES[first_induction_period.induction_programme.to_sym]
  end

  def appropriate_body_name
    return unless first_induction_period

    first_induction_period.appropriate_body.name
  end

  def active_induction_period
    # FIXME: this works if finished_on cannot be set to a future date
    # If that becomes possible, this query will need to be updated
    teacher.induction_periods.ongoing.first
  end

private

  def first_induction_period
    @first_induction_period ||= teacher.induction_periods.first
  end
end
