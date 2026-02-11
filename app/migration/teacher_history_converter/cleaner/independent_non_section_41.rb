class TeacherHistoryConverter::Cleaner::IndependentNonSection41
  def initialize(raw_induction_records)
    @raw_induction_records = raw_induction_records
  end

  def induction_records = remove_independent_schools!

private

  def remove_independent_schools!
    @raw_induction_records.reject { |induction_record| independent_school_without_section_41_at_start?(induction_record) }
  end

  def has_bso_school?(induction_record)
    induction_record.school.school_type_name == "British schools overseas"
  end
end
