class Teachers::InductionPeriod
  attr_reader :teacher

  def initialize(teacher)
    @teacher = teacher
  end

  def induction_start_date
    first_induction_period&.started_on
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
