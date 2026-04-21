class TeacherHistoryConverter::Cleaner::CloseECTInductionRecordsEndingLaterThanCohortClosure
  # NOTE: this assumes that the `RemoveECTInductionRecordsStartingLaterThanCohortClosure` cleaner
  # has been run before this one, so there are no induction_records present with a start_date
  # later than the cohort closure date

  def initialize(raw_induction_records, participant_type)
    @raw_induction_records = raw_induction_records
    @participant_type = participant_type
  end

  def induction_records
    return @raw_induction_records unless ect?

    close_post_cohort_closure_ending_records!
  end

private

  def ect?
    @participant_type == :ect
  end

  def close_post_cohort_closure_ending_records!
    @raw_induction_records.each do |induction_record|
      cut_off_date = cut_off_dates.cut_off_date_for(cohort_year: induction_record.cohort_year)
      next if cut_off_date.blank?

      induction_record.end_date = cut_off_date if induction_record.end_date.blank? || induction_record.end_date > cut_off_date
    end
  end

  def cut_off_dates
    @cut_off_dates ||= TeacherHistoryConverter::CohortCutOffDate.new
  end
end
