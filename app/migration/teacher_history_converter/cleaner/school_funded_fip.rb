class TeacherHistoryConverter::Cleaner::SchoolFundedFip
  def initialize(raw_induction_records)
    @raw_induction_records = raw_induction_records
  end

  def induction_records = remove_school_funded_fip!

private

  def remove_school_funded_fip!
    @raw_induction_records.reject { |induction_record| is_school_funded_fip?(induction_record) }
  end

  def is_school_funded_fip?(induction_record)
    induction_record.training_programme == "school_funded_fip"
  end
end
