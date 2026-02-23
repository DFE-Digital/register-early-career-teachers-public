class TeacherHistoryConverter::Cleaner::SnipOngoingRecordsToInductionCompletionDate
  attr_reader :induction_completion_date

  def initialize(raw_induction_records, induction_completion_date: nil)
    @raw_induction_records = raw_induction_records
    @induction_completion_date = induction_completion_date
  end

  def induction_records
    return @raw_induction_records if induction_completion_date.nil?

    @raw_induction_records.map do |induction_record|
      if induction_record.end_date.nil?
        induction_record.end_date = induction_completion_date
      end

      induction_record
    end
  end
end
