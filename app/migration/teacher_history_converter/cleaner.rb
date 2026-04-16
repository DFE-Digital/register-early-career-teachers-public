class TeacherHistoryConverter::Cleaner
  attr_reader :induction_completion_date, :participant_type, :profile_id, :migration_mode, :states

  def initialize(raw_induction_records, participant_type:, profile_id:, induction_completion_date: nil, states: [], migration_mode: "latest_induction_records")
    @raw_induction_records = raw_induction_records
    @induction_completion_date = induction_completion_date
    @participant_type = participant_type
    @profile_id = profile_id
    @migration_mode = migration_mode.to_s
    @states = states
  end

  def induction_records
    @induction_records ||= clean!
  end

private

  def clean!
    if migration_mode == "all_induction_records"
      premium_clean!
    else
      economy_clean!
    end
  end

  def economy_clean!
    @raw_induction_records
      .then { remove_british_schools_overseas(it) }
      .then { remove_school_funded_fip(it) }
      .then { remove_independent_non_section_41(it) }
      .then { remove_provider_led_ect_without_partnerships(it) }
      .then { snip_ongoing_records_to_induction_completion_date(it) }
      .then { fix_service_start_dates(it) }
      .then { fix_corrupted_dates(it) }
      .then { fix_zero_day_periods(it) }
      .then { override_first_start_date_with_creation_date_if_earlier(it) }
      .then { override_first_start_date_for_induction_record_introduction(it) }
      .then { remove_future_withdrawn_or_deferred_records(it) }
  end

  def premium_clean!
    @raw_induction_records
      .then { remove_british_schools_overseas(it) }
      .then { remove_school_funded_fip(it) }
      .then { remove_independent_non_section_41(it) }
      .then { remove_post_induction_completion_records(it) }
      .then { close_ongoing_records_after_induction_completion(it) }
      .then { remove_records_with_matching_withdrawn_and_deferred_states(it) }
      .then { remove_2021_and_2022_cohort_ect_records_starting_after_cohort_closure(it) }
      .then { close_2021_and_2022_cohort_records_ongoing_or_ending_after_cohort_closure(it) }
  end

  def remove_british_schools_overseas(induction_records)
    TeacherHistoryConverter::Cleaner::BritishSchoolsOverseas.new(induction_records).induction_records
  end

  def remove_school_funded_fip(induction_records)
    TeacherHistoryConverter::Cleaner::SchoolFundedFip.new(induction_records).induction_records
  end

  def remove_independent_non_section_41(induction_records)
    TeacherHistoryConverter::Cleaner::IndependentNonSection41.new(induction_records).induction_records
  end

  def remove_provider_led_ect_without_partnerships(induction_records)
    TeacherHistoryConverter::Cleaner::ProviderLedECTWithoutPartnership.new(induction_records, participant_type).induction_records
  end

  def fix_service_start_dates(induction_records)
    TeacherHistoryConverter::Cleaner::ServiceStartDate.new(induction_records).induction_records
  end

  def fix_corrupted_dates(induction_records)
    TeacherHistoryConverter::Cleaner::CorruptedDates.new(induction_records).induction_records
  end

  def fix_zero_day_periods(induction_records)
    TeacherHistoryConverter::Cleaner::ZeroDay.new(induction_records).induction_records
  end

  def override_first_start_date_with_creation_date_if_earlier(induction_records)
    TeacherHistoryConverter::Cleaner::OverrideFirstStartDateWithCreationDateIfEarlier.new(induction_records).induction_records
  end

  def override_first_start_date_for_induction_record_introduction(induction_records)
    TeacherHistoryConverter::Cleaner::OverrideFirstStartDateForInductionRecordIntroduction.new(induction_records).induction_records
  end

  def snip_ongoing_records_to_induction_completion_date(induction_records)
    TeacherHistoryConverter::Cleaner::SnipOngoingRecordsToInductionCompletionDate.new(induction_records, induction_completion_date:).induction_records
  end

  def remove_records_with_matching_withdrawn_and_deferred_states(induction_records)
    TeacherHistoryConverter::Cleaner::RemoveRecordsWithMatchingWithdrawnAndDeferredStates.new(induction_records, states:).induction_records
  end

  def remove_future_withdrawn_or_deferred_records(induction_records)
    TeacherHistoryConverter::Cleaner::RemoveFutureWithdrawnOrDeferredRecords.new(induction_records).induction_records
  end

  def remove_post_induction_completion_records(induction_records)
    TeacherHistoryConverter::Cleaner::RemovePostInductionCompletionRecords.new(induction_records, induction_completion_date:, profile_id:).induction_records
  end

  def close_ongoing_records_after_induction_completion(induction_records)
    TeacherHistoryConverter::Cleaner::CloseOngoingRecordsAfterInductionCompletion.new(induction_records, induction_completion_date:).induction_records
  end

  def remove_2021_and_2022_cohort_ect_records_starting_after_cohort_closure(induction_records)
    TeacherHistoryConverter::Cleaner::RemoveECTInductionRecordsStartingLaterThanCohortClosure.new(induction_records, participant_type).induction_records
  end

  def close_2021_and_2022_cohort_records_ongoing_or_ending_after_cohort_closure(induction_records)
    induction_records
  end
end
