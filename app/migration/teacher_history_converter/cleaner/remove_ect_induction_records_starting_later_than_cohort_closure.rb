class TeacherHistoryConverter::Cleaner::RemoveECTInductionRecordsStartingLaterThanCohortClosure
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
      cut_off_date = cut_off_dates.cut_off_date_for(cohort_year: induction_record.cohort_year)

      cut_off_date.present? && induction_record.start_date >= cut_off_date
    end
  end

  def cut_off_dates
    @cut_off_dates ||= TeacherHistoryConverter::CohortCutOffDate.new
  end
end
