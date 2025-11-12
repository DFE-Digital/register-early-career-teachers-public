module DataFixes
  INDUCTION_RECORDS_ADDED_DATE = Date.new(2022, 2, 9)

  # NOTE: this doesn't account for induction record groups so will set the start
  # for the first of each group
  def corrected_start_date(induction_record:, sequence_number:)
    if sequence_number.zero?
      if induction_record.start_date.to_date == INDUCTION_RECORDS_ADDED_DATE
        Date.new(2021, 9, 1)
      else
        [induction_record.start_date, induction_record.created_at].min
      end
    else
      induction_record.start_date
    end
  end
end
