class TeacherHistoryConverter::Cleaner::FixFirstStartDate
  def initialize(raw_induction_records)
    @raw_induction_records = raw_induction_records
  end

  def induction_records
    @raw_induction_records.dup.tap do |fixed_induction_records|
      first_ir = fixed_induction_records[0]

      first_ir.start_date = [first_ir.start_date, first_ir.created_at.to_date].min
    end
  end
end
