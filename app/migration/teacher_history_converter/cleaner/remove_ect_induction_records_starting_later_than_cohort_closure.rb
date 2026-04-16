class TeacherHistoryConverter::Cleaner::RemoveECTInductionRecordsStartingLaterThanCohortClosure
  include TeacherHistoryConverter::Cleaner::CohortCutOffDates

  def initialize(raw_induction_records, participant_type)
    @raw_induction_records = raw_induction_records
    @participant_type = participant_type
  end

  def induction_records
    return @raw_induction_records unless ect?

    remove_post_cohort_closure_records!
  end

private

  def ect?
    @participant_type == :ect
  end

  def remove_post_cohort_closure_records!
    @raw_induction_records.reject do |induction_record|
      (induction_record.cohort_year == 2021 && induction_record.start_date >= COHORT_2021_CUTOFF_DATE) ||
        (induction_record.cohort_year == 2022 && induction_record.start_date >= COHORT_2022_CUTOFF_DATE)
    end
  end
end
