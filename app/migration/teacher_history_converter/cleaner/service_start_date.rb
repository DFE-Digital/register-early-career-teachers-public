class TeacherHistoryConverter::Cleaner::ServiceStartDate
  SERVICE_START_DATE = Date.new(2021, 9, 1)

  attr_reader :raw_induction_records

  def initialize(raw_induction_records)
    @raw_induction_records = raw_induction_records
  end

  def induction_records
    raw_induction_records.each_with_index.map do |induction_record, index|
      correct_end_date_for_pre_service_start(induction_record, index)
    end
  end

private

  # Corrects end dates that fall before SERVICE_START_DATE (2021-09-01)
  # - First IR: use start_date of next induction record (if valid), otherwise created_at
  # - Subsequent IRs: use created_at of that induction record
  def correct_end_date_for_pre_service_start(induction_record, index)
    next_induction_record = raw_induction_records[index + 1]
    corrected_end_date = end_date_corrected_for_pre_service_start(induction_record, next_induction_record)

    induction_record.end_date = corrected_end_date
    induction_record
  end

  def end_date_corrected_for_pre_service_start(induction_record, next_induction_record)
    return induction_record.end_date unless end_date_before_service_start?(induction_record)

    if next_induction_record && start_date_on_or_after_service_start?(next_induction_record)
      next_induction_record.start_date
    else
      induction_record.created_at.to_date
    end
  end

  def end_date_before_service_start?(induction_record)
    return false if induction_record.end_date.blank?

    induction_record.end_date.to_date < SERVICE_START_DATE
  end

  def start_date_on_or_after_service_start?(induction_record)
    induction_record.start_date.to_date >= SERVICE_START_DATE
  end
end
