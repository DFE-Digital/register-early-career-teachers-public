class TeacherHistoryConverter::Cleaner::RemoveFutureWithdrawnOrDeferredRecords
  attr_reader :raw_induction_records

  def initialize(raw_induction_records)
    @raw_induction_records = raw_induction_records
  end

  def induction_records
    raw_induction_records.reject { it.future? && it.withdrawn_or_deferred? }
  end
end
