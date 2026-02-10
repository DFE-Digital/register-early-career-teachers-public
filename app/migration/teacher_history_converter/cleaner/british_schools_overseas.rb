class TeacherHistoryConverter::Cleaner::BritishSchoolsOverseas
  def initialize(raw_induction_records)
    @raw_induction_records = raw_induction_records
  end

  def induction_records = remove_bso_schools!

private

  def remove_bso_schools!
    @raw_induction_records.reject { |induction_record| has_bso_school?(induction_record) }
  end

  def has_bso_school?(induction_record)
    induction_record.school.school_type_name == "British schools overseas"
  end
end
