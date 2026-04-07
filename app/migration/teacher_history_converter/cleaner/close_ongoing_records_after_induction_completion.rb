class TeacherHistoryConverter::Cleaner::CloseOngoingRecordsAfterInductionCompletion
  def initialize(raw_induction_records, induction_completion_date:)
    @raw_induction_records = raw_induction_records
    @induction_completion_date = induction_completion_date
  end

  def induction_records
    return @raw_induction_records if @induction_completion_date.blank?

    close_ongoing_records!
  end

private

  # these would be records that matched the exemption CSV and needed to be kept despite
  # being after the induction_completion_date

  def close_ongoing_records!
    @raw_induction_records.each do |induction_record|
      next if induction_record.end_date.present?

      induction_record.end_date = [induction_record.start_date + 1.day, @induction_completion_date].max
    end
  end
end
