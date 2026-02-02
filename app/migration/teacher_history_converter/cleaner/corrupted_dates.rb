class TeacherHistoryConverter::Cleaner::CorruptedDates
  def initialize(raw_induction_records)
    @raw_induction_records = raw_induction_records
  end

  def induction_records = fix_corrupted_dates!

private

  def fix_corrupted_dates!
    fixed_induction_records = []

    @raw_induction_records.each do |raw_ir|
      fixed_induction_records << if right_way_round?(raw_ir)
                                   raw_ir
                                 elsif raw_ir.end_date.nil?
                                   raw_ir
                                 else
                                   # When the dates are 'inverted', where the end
                                   # date is on or before the start date, convert
                                   # the record to a (one day) 'stub' that the
                                   # converter can deal with
                                   raw_ir.tap do
                                     it.start_date = raw_ir.end_date
                                     it.end_date = raw_ir.end_date + 1.day
                                   end
                                 end
    end

    fixed_induction_records
  end

  def right_way_round?(induction_record)
    induction_record.end_date && induction_record.end_date >= induction_record.start_date
  end
end
