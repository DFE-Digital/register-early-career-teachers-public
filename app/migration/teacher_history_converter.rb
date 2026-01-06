class TeacherHistoryConverter
  attr_reader :ecf1_teacher_history

  def initialize(ecf1_teacher_history:)
    @ecf1_teacher_history = ecf1_teacher_history
  end

  def convert_to_ecf2!
    ECF2TeacherHistory.new(
      teacher_row:,
      ect_at_school_period_rows:,
      mentor_at_school_period_rows:
    )
  end

private

  def date_corrector
    @date_corrector ||= DateCorrector.new(
      ect_induction_completion_date: ecf1_teacher_history.ect&.induction_completion_date,
      mentor_completion_date: ecf1_teacher_history.mentor&.mentor_completion_date
    )
  end

  def teacher_row
    ECF2TeacherHistory::TeacherRow.new(
      trn: ecf1_teacher_history.user.trn,
      trnless: ecf1_teacher_history.user.trn.blank?,
      trs_first_name: parsed_name.first_name,
      trs_last_name: parsed_name.last_name,
      api_id: ecf1_teacher_history.user.user_id,
      api_ect_training_record_id: ecf1_teacher_history.ect&.participant_profile_id,
      api_mentor_training_record_id: ecf1_teacher_history.mentor&.participant_profile_id,
      api_updated_at: calculate_api_updated_at,
      ect_migration_mode: ecf1_teacher_history.ect&.migration_mode || "not_migrated",
      ect_pupil_premium_uplift: ecf1_teacher_history.ect&.pupil_premium_uplift,
      ect_sparsity_uplift: ecf1_teacher_history.ect&.sparsity_uplift,
      ect_payments_frozen_year: ecf1_teacher_history.ect&.payments_frozen_cohort_start_year,
      mentor_migration_mode: ecf1_teacher_history.mentor&.migration_mode || "not_migrated",
      mentor_payments_frozen_year: ecf1_teacher_history.mentor&.payments_frozen_cohort_start_year,
      created_at: ecf1_teacher_history.user.created_at,
      updated_at: ecf1_teacher_history.user.updated_at
    )
  end

  # Calculates the api_updated_at timestamp using ECF's ParticipantSerializer logic:
  # The max of participant_profiles.updated_at, user.updated_at,
  # participant_identities.updated_at, and induction_records.updated_at
  def calculate_api_updated_at
    timestamps = [ecf1_teacher_history.user.updated_at]

    if ecf1_teacher_history.ect.present?
      timestamps << ecf1_teacher_history.ect.updated_at
      timestamps.concat(ecf1_teacher_history.ect.induction_records.map(&:updated_at))
    end

    if ecf1_teacher_history.mentor.present?
      timestamps << ecf1_teacher_history.mentor.updated_at
      timestamps.concat(ecf1_teacher_history.mentor.induction_records.map(&:updated_at))
    end

    # participant_identities.updated_at is captured in user if needed
    timestamps.concat(ecf1_teacher_history.participant_identity_updated_ats || [])

    timestamps.compact.max
  end

  def ect_at_school_period_rows
    return [] if ecf1_teacher_history.ect.blank?

    induction_records = ecf1_teacher_history.ect.induction_records(migration_mode:)

    case migration_mode
    when :latest_induction_records
      TeacherHistoryConverter::ECT::LatestInductionRecords.new(induction_records)
    when :all_induction_records
      TeacherHistoryConverter::ECT::AllInductionRecords.new(induction_records)
    end
  end

  def migration_mode
    :latest_induction_records
  end

  def build_ect_training_period_rows(school_induction_records, all_induction_records)
    training_period_rows = []
    current_training = nil

    school_induction_records.each do |induction_record|
      index = all_induction_records.index(induction_record)

      if training_changed?(current_training, induction_record)
        current_training = induction_record
        training_period_rows << ECF2TeacherHistory::TrainingPeriodRow.new(
          **ect_training_period_attributes(induction_record, school_induction_records, index),
          is_ect: true
        )
      else
        update_training_period_end_date(training_period_rows.last, induction_record, school_induction_records, :ect)
      end
    end

    training_period_rows
  end

  def mentor_at_school_period_rows
    return [] if ecf1_teacher_history.mentor.blank?

    induction_records = ecf1_teacher_history.mentor.induction_records(migration_mode:)

    case migration_mode
    when :latest_induction_records
      TeacherHistoryConverter::Mentor::LatestInductionRecords.new(induction_records)
    when :all_induction_records
      TeacherHistoryConverter::Mentor::AllInductionRecords.new(induction_records)
    end
  end

  def build_mentor_training_period_rows_for_school(school_induction_records, all_induction_records)
    training_period_rows = []
    current_training = nil

    school_induction_records.each do |induction_record|
      index = all_induction_records.index(induction_record)

      training_programme = ecf2_training_programme(induction_record.training_programme)
      next unless training_programme == "provider_led"

      if training_changed?(current_training, induction_record)
        current_training = induction_record
        training_period_rows << ECF2TeacherHistory::TrainingPeriodRow.new(
          **mentor_training_period_attributes(induction_record, school_induction_records, index)
        )
      else
        update_training_period_end_date(training_period_rows.last, induction_record, school_induction_records, :mentor)
      end
    end

    training_period_rows
  end

  def mentor_training_period_attributes(induction_record, induction_records, index)
    training_period_attributes(induction_record, induction_records, index, participant_type: :mentor)
  end

  def ect_training_period_attributes(induction_record, induction_records, index)
    training_period_attributes(induction_record, induction_records, index, participant_type: :ect)
  end

  def build_mentorship_period_rows(induction_record)
    return [] if induction_record.mentor_profile_id.blank?

    mentor_teacher = Teacher.find_by(api_mentor_training_record_id: induction_record.mentor_profile_id)
    return [] if mentor_teacher.nil?

    started_on = mentorship_period_start_date(induction_record)
    finished_on = induction_record.end_date

    mentor_data = ECF2TeacherHistory::MentorData.new(
      trn: mentor_teacher.trn,
      urn: induction_record.school.urn,
      started_on:,
      finished_on:
    )

    [
      ECF2TeacherHistory::MentorshipPeriodRow.new(
        started_on:,
        finished_on:,
        ecf_start_induction_record_id: induction_record.induction_record_id,
        ecf_end_induction_record_id: induction_record.induction_record_id,
        mentor_data:
      )
    ]
  end

  # For mentorship periods, use simple min of start_date and created_at
  def mentorship_period_start_date(induction_record)
    [induction_record.start_date, induction_record.created_at.to_date].min
  end

  def training_period_attributes(induction_record, induction_records, index, participant_type:)
    {
      started_on: date_corrector.corrected_start_date(induction_record, index),
      finished_on: date_corrector.corrected_training_period_end_date(induction_record, induction_records, participant_type:),
      training_programme: ecf2_training_programme(induction_record.training_programme),
      **deferral_attributes(induction_record),
      **withdrawal_attributes(induction_record),
      lead_provider_info: induction_record.training_provider_info&.lead_provider_info,
      delivery_partner_info: induction_record.training_provider_info&.delivery_partner_info,
      schedule_info: induction_record.schedule_info,
      contract_period_year: induction_record.cohort_year,
      created_at: induction_record.created_at,
      ecf_start_induction_record_id: induction_record.induction_record_id,
      school: induction_record.school
    }
  end

  def parsed_name
    @parsed_name ||= Teachers::FullNameParser.new(full_name: ecf1_teacher_history.user.full_name)
  end

  def ecf2_training_programme(ecf1_training_programme)
    Mappers::TrainingProgrammeMapper.new(ecf1_training_programme.to_s).mapped_value
  end

  def deferral_attributes(induction_record)
    return {} unless induction_record.training_status == "deferred"

    {
      deferred_at: induction_record.end_date,
      deferral_reason: "???"
    }
  end

  def withdrawal_attributes(induction_record)
    return {} unless induction_record.training_status == "withdrawn"

    {
      withdrawn_at: induction_record.end_date,
      withdrawal_reason: "???"
    }
  end

  # Groups consecutive induction records by school URN
  # Returns array of [school, [induction_records]] pairs preserving order
  def group_induction_records_by_school(induction_records)
    induction_records.chunk(&:school).to_a
  end

  # Determines if training has changed between IRs (requiring a new TrainingPeriod)
  def training_changed?(current_training_ir, induction_record)
    return true if current_training_ir.nil?

    current_programme = ecf2_training_programme(current_training_ir.training_programme)
    new_programme = ecf2_training_programme(induction_record.training_programme)

    # Training programme changed
    return true if current_programme != new_programme

    # Lead provider changed
    current_lp = current_training_ir.training_provider_info&.lead_provider_info&.ecf1_id
    new_lp = induction_record.training_provider_info&.lead_provider_info&.ecf1_id
    return true if current_lp != new_lp

    # Delivery partner changed
    current_dp = current_training_ir.training_provider_info&.delivery_partner_info&.ecf1_id
    new_dp = induction_record.training_provider_info&.delivery_partner_info&.ecf1_id
    return true if current_dp != new_dp

    # Was deferred/withdrawn but now active
    was_deferred_or_withdrawn = current_training_ir.training_status.in?(%w[deferred withdrawn])
    now_active = induction_record.training_status == "active"
    return true if was_deferred_or_withdrawn && now_active

    false
  end

  def update_training_period_end_date(training_period_row, induction_record, school_induction_records, participant_type)
    return if training_period_row.nil?

    new_end_date = date_corrector.corrected_training_period_end_date(
      induction_record,
      school_induction_records,
      participant_type:
    )

    training_period_row.instance_variable_set(:@finished_on, new_end_date)
    training_period_row.instance_variable_set(:@ecf_end_induction_record_id, induction_record.induction_record_id)

    if induction_record.training_status == "deferred"
      training_period_row.instance_variable_set(:@deferred_at, induction_record.end_date)
      training_period_row.instance_variable_set(:@deferral_reason, "???")
    elsif induction_record.training_status == "withdrawn"
      training_period_row.instance_variable_set(:@withdrawn_at, induction_record.end_date)
      training_period_row.instance_variable_set(:@withdrawal_reason, "???")
    end
  end
end
