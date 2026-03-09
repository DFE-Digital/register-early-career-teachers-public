class TeacherHistoryConverter::Cleaner
  attr_reader :induction_completion_date, :participant_type, :migration_mode

  def initialize(raw_induction_records, participant_type:, induction_completion_date: nil, migration_mode: "latest_induction_records")
    @raw_induction_records = raw_induction_records
    @induction_completion_date = induction_completion_date
    @participant_type = participant_type
    @migration_mode = migration_mode.to_s
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
    remove_british_schools_overseas(@raw_induction_records)
      .then { remove_school_funded_fip(it) }
      .then { remove_independent_non_section_41(it) }
      .then { remove_provider_led_ect_without_partnerships(it) }
      .then { snip_ongoing_records_to_induction_completion_date(it, induction_completion_date:) }
      .then { fix_service_start_dates(it) }
      .then { fix_corrupted_dates(it) }
      .then { fix_zero_day_periods(it) }
      .then { override_first_start_date_with_creation_date_if_earlier(it) }
      .then { override_first_start_date_for_induction_record_introduction(it) }
  end

  def premium_clean!
    remove_british_schools_overseas(@raw_induction_records)
      .then { remove_school_funded_fip(it) }
      .then { remove_independent_non_section_41(it) }
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

  def snip_ongoing_records_to_induction_completion_date(induction_records, induction_completion_date:)
    TeacherHistoryConverter::Cleaner::SnipOngoingRecordsToInductionCompletionDate.new(induction_records, induction_completion_date:).induction_records
  end
end
