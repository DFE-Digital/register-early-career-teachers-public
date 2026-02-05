class TeacherHistoryConverter::MigrationStrategy
  attr_accessor :ecf1_teacher_history

  def initialize(ecf1_teacher_history)
    @ecf1_teacher_history = ecf1_teacher_history
  end

  # :earliest_induction_records or :latest_induction_records
  def strategy
    :latest_induction_records
  end
end
