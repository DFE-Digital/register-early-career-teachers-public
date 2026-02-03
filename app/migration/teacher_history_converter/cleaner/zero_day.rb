class TeacherHistoryConverter::Cleaner::ZeroDay
  def initialize(raw_induction_records)
    @raw_induction_records = raw_induction_records
  end

  def induction_records = fix_zero_day_records!

private

  def fix_zero_day_records!
    fixed_induction_records = []

    @raw_induction_records.each do |raw_ir|
      fixed_induction_records << if raw_ir.end_date.nil?
                                   raw_ir
                                 elsif duration_greater_than_zero?(raw_ir)
                                   raw_ir
                                 else
                                   # We don't allow 0 day records (where the start and
                                   # end date is the same day.
                                   raw_ir.tap { it.end_date = raw_ir.end_date + 1.day }
                                 end
    end

    fixed_induction_records
  end

  def duration_greater_than_zero?(induction_record)
    induction_record.end_date.to_date > induction_record.start_date.to_date
  end
end
