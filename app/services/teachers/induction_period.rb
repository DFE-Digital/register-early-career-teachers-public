class Teachers::InductionPeriod
  attr_reader :teacher

  def initialize(teacher)
    @teacher = teacher
  end

  # @return [Date, nil]
  def induction_start_date
    teacher.first_induction_period&.started_on
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

  # @param date [Date]
  # @return [Boolean]
  def overlapping_with?(date)
    teacher.induction_periods.ongoing_on(date).exists?
  end

  delegate :last_induction_period, to: :teacher
end
