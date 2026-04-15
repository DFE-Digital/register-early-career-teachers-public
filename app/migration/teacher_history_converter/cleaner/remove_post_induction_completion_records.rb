class TeacherHistoryConverter::Cleaner::RemovePostInductionCompletionRecords
  attr_reader :induction_completion_date, :profile_id

  def initialize(induction_records, induction_completion_date:, profile_id:)
    @raw_induction_records = induction_records
    @induction_completion_date = induction_completion_date
    @profile_id = profile_id
  end

  def induction_records = remove_post_induction_completion_records!

private

  def remove_post_induction_completion_records!
    return @raw_induction_records if induction_completion_date.blank?

    @raw_induction_records.reject do |induction_record|
      induction_record.start_date >= induction_completion_date && can_be_removed?(induction_record)
    end
  end

  def can_be_removed?(induction_record)
    !needs_to_be_kept?(induction_record)
  end

  def needs_to_be_kept?(induction_record)
    lead_provider_id = induction_record.training_provider_info&.lead_provider_info&.ecf1_id
    return false if lead_provider_id.blank?

    combo_checker.keep?(profile_id:, lead_provider_id:, cohort_year: induction_record.cohort_year)
  end

  def combo_checker
    @combo_checker ||= TeacherHistoryConverter::PostInductionCompletionComboCheck.new
  end
end
