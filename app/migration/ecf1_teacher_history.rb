class ECF1TeacherHistory
  class InvalidPeriodType < StandardError; end

  InductionRecordRow = Struct.new(:start_date, :end_date)

  ECT = Struct.new(:induction_records, :states)

  attr_reader :trn, :full_name, :ect_induction_record_rows, :mentor_induction_record_rows

  def initialize(trn:, full_name:, ect_induction_record_rows: [], mentor_induction_record_rows: [])
    @trn = trn
    @full_name = full_name
    @ect_induction_record_rows = ect_induction_record_rows
    @mentor_induction_record_rows = mentor_induction_record_rows
  end

  def self.build(user:, teacher_profile:, ect_induction_records:, mentor_induction_records:)
    new(
      trn: teacher_profile.trn,
      full_name: user.full_name,
      ect_induction_record_rows: ect_induction_records.sort_by(&:created_at).map do
        InductionRecordRow.new(start_date: it.start_date, end_date: it.end_date)
      end,
      mentor_induction_record_rows: mentor_induction_records.sort_by(&:created_at).map do
        InductionRecordRow.new(start_date: it.start_date, end_date: it.end_date)
      end
    )
  end
end
