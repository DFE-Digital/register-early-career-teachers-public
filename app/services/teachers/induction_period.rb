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
    return unless last_induction_period

    ::INDUCTION_PROGRAMMES[last_induction_period.induction_programme.to_sym]
  end

  def appropriate_body_name
    return unless last_induction_period

    last_induction_period.appropriate_body.name
  end

  # FIXME: this works if finished_on cannot be set to a future date
  # If that becomes possible, this query will need to be updated
  #
  # @return [InductionPeriod, nil]
  def ongoing_induction_period
    teacher.induction_periods.ongoing.first
  end

  def last_induction_period
    induction_periods.last
  end

private

  def first_induction_period
    induction_periods.first
  end

  def induction_periods
    @induction_periods ||= teacher.induction_periods.order(:started_on)
  end
end
