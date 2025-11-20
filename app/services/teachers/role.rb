class Teachers::Role
  attr_reader :teacher, :school

  def initialize(teacher:, school: nil)
    @teacher = teacher
    @school = school
  end

  def to_s
    roles.join(" & ")
  end

  def roles
    @roles ||= determine_roles
  end

private

  def determine_roles
    result = []

    ect_periods = school ? teacher.ect_at_school_periods.where(school:) : teacher.ect_at_school_periods
    mentor_periods = school ? teacher.mentor_at_school_periods.where(school:) : teacher.mentor_at_school_periods
    induction_periods = school ? ::InductionPeriod.none : teacher.induction_periods

    if ect_periods.ongoing.any?
      result << "ECT"
    elsif ect_periods.any?
      result << "ECT (Inactive)"
    end

    if mentor_periods.ongoing.any?
      result << "Mentor"
    elsif mentor_periods.any?
      result << "Mentor (Inactive)"
    end

    if result.empty? && induction_periods.any?
      result << "ECT (Inactive)"
    end

    result
  end
end
