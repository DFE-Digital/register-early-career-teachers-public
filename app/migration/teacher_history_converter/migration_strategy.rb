class TeacherHistoryConverter::MigrationStrategy
  attr_accessor :ecf1_teacher_history

  def initialize(ecf1_teacher_history)
    @ecf1_teacher_history = ecf1_teacher_history
  end

  def strategy = :all_induction_records
end
