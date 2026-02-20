class TeacherHistoryConverter::MigrationStrategy
  attr_accessor :ecf1_teacher_history

  def initialize(ecf1_teacher_history)
    @ecf1_teacher_history = ecf1_teacher_history
  end

  def strategy
    if mentor_induction_records_count <= 1 && ect_induction_records_count <= 1
      :all_induction_records
    else
      :latest_induction_records
    end
  end

private

  def ect_induction_records_count
    ecf1_teacher_history.ect&.induction_records&.count || 0
  end

  def mentor_induction_records_count
    ecf1_teacher_history.mentor&.induction_records&.count || 0
  end
end
