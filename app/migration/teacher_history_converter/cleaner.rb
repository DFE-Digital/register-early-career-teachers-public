class TeacherHistoryConverter::Cleaner
  def initialize(raw_induction_records)
    @raw_induction_records = raw_induction_records
  end

  def induction_records
    @induction_records ||= clean!
  end

private

  def clean!
    remove_british_schools_overseas(@raw_induction_records)
      .then { |induction_records| fix_service_start_dates(induction_records) }
      .then { |induction_records| fix_corrupted_dates(induction_records) }
      .then { |induction_records| fix_zero_day_periods(induction_records) }
  end

  def remove_british_schools_overseas(induction_records)
    TeacherHistoryConverter::Cleaner::BritishSchoolsOverseas.new(induction_records).induction_records
  end

  def fix_service_start_dates(induction_records)
    TeacherHistoryConverter::Cleaner::ServiceStartDate.new(induction_records).induction_records
  end

  def fix_corrupted_dates(induction_records)
    TeacherHistoryConverter::Cleaner::CorruptedDates.new(induction_records).induction_records
  end

  def fix_zero_day_periods(induction_records)
    TeacherHistoryConverter::Cleaner::ZeroDay.new(induction_records).induction_records
  end
end
