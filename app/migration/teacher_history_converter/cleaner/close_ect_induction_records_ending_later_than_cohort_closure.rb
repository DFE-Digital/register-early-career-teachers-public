class TeacherHistoryConverter::Cleaner::CloseECTInductionRecordsEndingLaterThanCohortClosure
  include TeacherHistoryConverter::Cleaner::CohortCutOffDates

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
      if needs_end_date_change?(induction_record:, cohort_year: 2021, cutoff_date: COHORT_2021_CUTOFF_DATE)
        induction_record.end_date = COHORT_2021_CUTOFF_DATE
      elsif needs_end_date_change?(induction_record:, cohort_year: 2022, cutoff_date: COHORT_2022_CUTOFF_DATE)
        induction_record.end_date = COHORT_2022_CUTOFF_DATE
      end
    end
  end

  def needs_end_date_change?(induction_record:, cohort_year:, cutoff_date:)
    induction_record.cohort_year == cohort_year && (induction_record.end_date.blank? || induction_record.end_date > cutoff_date)
  end
end
