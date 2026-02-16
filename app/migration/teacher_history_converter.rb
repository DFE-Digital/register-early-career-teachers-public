class TeacherHistoryConverter
  include TeacherHistoryConverter::CalculatedAttributes

  attr_reader :ecf1_teacher_history, :migration_mode

  def initialize(ecf1_teacher_history:, migration_mode: nil)
    @ecf1_teacher_history = ecf1_teacher_history

    @migration_mode = migration_mode || select_migration_mode
  end

  def convert_to_ecf2!
    ECF2TeacherHistory.new(
      teacher:,
      ect_at_school_periods:,
      mentor_at_school_periods:
    )
  end

private

  def select_migration_mode
    MigrationStrategy.new(ecf1_teacher_history).strategy
  end

  def date_corrector
    @date_corrector ||= DateCorrector.new(
      ect_induction_completion_date: ecf1_teacher_history.ect&.induction_completion_date,
      mentor_completion_date: ecf1_teacher_history.mentor&.mentor_completion_date
    )
  end

  def teacher
    ECF2TeacherHistory::Teacher.new(
      trn: ecf1_teacher_history.user.trn,
      trnless: ecf1_teacher_history.user.trn.blank?,
      trs_first_name: parsed_name.first_name,
      trs_last_name: parsed_name.last_name,
      corrected_name: ecf1_teacher_history.user.full_name,
      api_id: ecf1_teacher_history.user.user_id,
      api_ect_training_record_id: ecf1_teacher_history.ect&.participant_profile_id,
      api_mentor_training_record_id: ecf1_teacher_history.mentor&.participant_profile_id,
      api_updated_at: participant_api_updated_at(ecf1_teacher_history:),
      migration_mode:,
      ect_pupil_premium_uplift: ecf1_teacher_history.ect&.pupil_premium_uplift,
      ect_sparsity_uplift: ecf1_teacher_history.ect&.sparsity_uplift,
      ect_payments_frozen_year: ecf1_teacher_history.ect&.payments_frozen_cohort_start_year,
      mentor_payments_frozen_year: ecf1_teacher_history.mentor&.payments_frozen_cohort_start_year,
      created_at: ecf1_teacher_history.user.created_at,
      updated_at: ecf1_teacher_history.user.updated_at
    )
  end

  def ect_at_school_periods
    return [] if ecf1_teacher_history.ect.blank?

    trn = ecf1_teacher_history.user.trn
    profile_id = ecf1_teacher_history.ect.participant_profile_id
    raw_induction_records = ecf1_teacher_history.ect.induction_records
    induction_records = TeacherHistoryConverter::Cleaner.new(raw_induction_records).induction_records
    mentor_at_school_periods = ecf1_teacher_history.ect.mentor_at_school_periods

    case migration_mode
    when :latest_induction_records
      TeacherHistoryConverter::ECT::LatestInductionRecords.new(trn:, profile_id:, induction_records:, mentor_at_school_periods:)
        .ect_at_school_periods
        .then { |at_school_periods| override_first_at_school_period_created_at(at_school_periods, ecf1_teacher_history.ect.created_at) }
    when :all_induction_records
      TeacherHistoryConverter::ECT::AllInductionRecords.new(induction_records).ect_at_school_periods
    end
  end

  def parsed_name
    @parsed_name ||= Teachers::FullNameParser.new(full_name: ecf1_teacher_history.user.full_name)
  end

  def mentor_at_school_periods
    return [] if ecf1_teacher_history.mentor.blank?

    trn = ecf1_teacher_history.user.trn
    profile_id = ecf1_teacher_history.mentor.participant_profile_id
    raw_induction_records = ecf1_teacher_history.mentor.induction_records
    induction_records = TeacherHistoryConverter::Cleaner.new(raw_induction_records).induction_records

    case migration_mode
    when :latest_induction_records
      TeacherHistoryConverter::Mentor::LatestInductionRecords.new(trn:, profile_id:, induction_records:)
        .mentor_at_school_periods
        .then { |at_school_periods| override_first_at_school_period_created_at(at_school_periods, ecf1_teacher_history.mentor.created_at) }
    when :all_induction_records
      TeacherHistoryConverter::Mentor::AllInductionRecords.new(induction_records).mentor_at_school_periods
    end
  end

  # in ECF1 we use the participant profile `created_at`, but as
  # there's no equivalent in RECT we are taking the school period's
  # created_at.
  #
  # Are we able to populate the earliest school period with the
  # created at from the participant profile during migration?
  def override_first_at_school_period_created_at(at_school_periods, participant_profile_created_at)
    return at_school_periods if at_school_periods.empty?

    at_school_periods[0].created_at = participant_profile_created_at
    at_school_periods
  end

  # This needs to work on all induction records so before any grouping wnd pre-washing
  def clean_top_level_induction_records(induction_records)
    TeacherHistoryConverter::Cleaner::IndependentNonSection41.new(induction_records).induction_records
  end

  # def build_mentorship_periods(induction_record)
  #   return [] if induction_record.mentor_profile_id.blank?
  #
  #   mentor_teacher = Teacher.find_by(api_mentor_training_record_id: induction_record.mentor_profile_id)
  #   return [] if mentor_teacher.nil?
  #
  #   started_on = mentorship_period_start_date(induction_record)
  #   finished_on = induction_record.end_date
  #
  #   mentor_data = ECF2TeacherHistory::MentorData.new(
  #     trn: mentor_teacher.trn,
  #     urn: induction_record.school.urn,
  #     started_on:,
  #     finished_on:
  #   )
  #
  #   [
  #     ECF2TeacherHistory::MentorshipPeriod.new(
  #       started_on:,
  #       finished_on:,
  #       ecf_start_induction_record_id: induction_record.induction_record_id,
  #       ecf_end_induction_record_id: induction_record.induction_record_id,
  #       mentor_data:
  #     )
  #   ]
  # end
  #
  # # For mentorship periods, use simple min of start_date and created_at
  # def mentorship_period_start_date(induction_record)
  #   [induction_record.start_date, induction_record.created_at.to_date].min
  # end
  #
  #
  # def deferral_attributes(induction_record)
  #   return {} unless induction_record.training_status == "deferred"
  #
  #   {
  #     deferred_at: induction_record.end_date,
  #     deferral_reason: "???"
  #   }
  # end
  #
  # def withdrawal_attributes(induction_record)
  #   return {} unless induction_record.training_status == "withdrawn"
  #
  #   {
  #     withdrawn_at: induction_record.end_date,
  #     withdrawal_reason: "???"
  #   }
  # end
  #
  # # Groups consecutive induction records by school URN
  # # Returns array of [school, [induction_records]] pairs preserving order
  # def group_induction_records_by_school(induction_records)
  #   induction_records.chunk(&:school).to_a
  # end
  #
  # # Determines if training has changed between IRs (requiring a new TrainingPeriod)
  # def training_changed?(current_training_ir, induction_record)
  #   return true if current_training_ir.nil?
  #
  #   current_programme = ecf2_training_programme(current_training_ir.training_programme)
  #   new_programme = ecf2_training_programme(induction_record.training_programme)
  #
  #   # Training programme changed
  #   return true if current_programme != new_programme
  #
  #   # Lead provider changed
  #   current_lp = current_training_ir.training_provider_info&.lead_provider_info&.ecf1_id
  #   new_lp = induction_record.training_provider_info&.lead_provider_info&.ecf1_id
  #   return true if current_lp != new_lp
  #
  #   # Delivery partner changed
  #   current_dp = current_training_ir.training_provider_info&.delivery_partner_info&.ecf1_id
  #   new_dp = induction_record.training_provider_info&.delivery_partner_info&.ecf1_id
  #   return true if current_dp != new_dp
  #
  #   # Was deferred/withdrawn but now active
  #   was_deferred_or_withdrawn = current_training_ir.training_status.in?(%w[deferred withdrawn])
  #   now_active = induction_record.training_status == "active"
  #   return true if was_deferred_or_withdrawn && now_active
  #
  #   false
  # end
  #
  # def update_training_period_end_date(training_period, induction_record, school_induction_records, participant_type)
  #   return if training_period.nil?
  #
  #   new_end_date = date_corrector.corrected_training_period_end_date(
  #     induction_record,
  #     school_induction_records,
  #     participant_type:
  #   )
  #
  #   training_period.instance_variable_set(:@finished_on, new_end_date)
  #   training_period.instance_variable_set(:@ecf_end_induction_record_id, induction_record.induction_record_id)
  #
  #   if induction_record.training_status == "deferred"
  #     training_period.instance_variable_set(:@deferred_at, induction_record.end_date)
  #     training_period.instance_variable_set(:@deferral_reason, "???")
  #   elsif induction_record.training_status == "withdrawn"
  #     training_period.instance_variable_set(:@withdrawn_at, induction_record.end_date)
  #     training_period.instance_variable_set(:@withdrawal_reason, "???")
  #   end
  # end
end
