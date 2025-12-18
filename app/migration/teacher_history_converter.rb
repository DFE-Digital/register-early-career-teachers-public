class TeacherHistoryConverter
  # Date when induction records were added to ECF - records with this start date
  # should use SERVICE_START_DATE instead
  INDUCTION_RECORDS_ADDED_DATE = Date.new(2022, 2, 9)
  SERVICE_START_DATE = Date.new(2021, 9, 1)

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

    induction_records = ecf1_teacher_history.ect.induction_records

    induction_records.each_with_index.map do |induction_record, index|
      ECF2TeacherHistory::ECTAtSchoolPeriodRow.new(
        **ect_induction_record_attributes(induction_record, induction_records, index),
        training_period_rows: [
          ECF2TeacherHistory::TrainingPeriodRow.new(
            **ect_training_period_attributes(induction_record, induction_records, index),
            is_ect: true
          )
        ]
      )
    end
  end

  def mentor_at_school_period_rows
    return [] if ecf1_teacher_history.mentor.blank?

    induction_records = ecf1_teacher_history.mentor.induction_records

    induction_records.each_with_index.map do |induction_record, index|
      ECF2TeacherHistory::MentorAtSchoolPeriodRow.new(
        **mentor_induction_record_attributes(induction_record, induction_records, index),
        training_period_rows: build_mentor_training_period_rows(induction_record, induction_records, index)
      )
    end
  end

  def mentor_induction_record_attributes(induction_record, induction_records, index)
    {
      started_on: corrected_start_date(induction_record, index),
      finished_on: corrected_end_date(induction_record, induction_records, participant_type: :mentor),
      school: Types::SchoolData.new(urn: induction_record.school_urn, name: nil),
      email: induction_record.preferred_identity_email
    }
  end

  def build_mentor_training_period_rows(induction_record, induction_records, index)
    # Mentors only have training periods for provider_led training
    training_programme = ecf2_training_programme(induction_record.training_programme)
    return [] unless training_programme == "provider_led"

    [ECF2TeacherHistory::TrainingPeriodRow.new(**mentor_training_period_attributes(induction_record, induction_records, index))]
  end

  def mentor_training_period_attributes(induction_record, induction_records, index)
    # training_period_attributes already handles mentor completion date logic via
    # corrected_training_period_end_date -> date_for_mentors_with_one_ir
    training_period_attributes(induction_record, induction_records, index, participant_type: :mentor)
  end

  def mentor_completion_date
    ecf1_teacher_history.mentor&.mentor_completion_date
  end

  def the_31st_august_following(date)
    year = date.month > 8 ? date.year + 1 : date.year
    Date.new(year, 8, 31)
  end

  def ect_induction_record_attributes(induction_record, induction_records, index)
    {
      started_on: corrected_start_date(induction_record, index),
      finished_on: corrected_end_date(induction_record, induction_records, participant_type: :ect),
      school: Types::SchoolData.new(urn: induction_record.school_urn, name: "Thing"),
      email: induction_record.preferred_identity_email,
      mentorship_period_rows: build_mentorship_period_rows(induction_record),
      appropriate_body: induction_record.appropriate_body
    }
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
      urn: induction_record.school_urn,
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
      started_on: corrected_start_date(induction_record, index),
      finished_on: corrected_training_period_end_date(induction_record, induction_records, participant_type:),
      training_programme: ecf2_training_programme(induction_record.training_programme),
      **deferral_attributes(induction_record),
      **withdrawal_attributes(induction_record),
      lead_provider_info: induction_record.training_provider_info&.lead_provider_info,
      delivery_partner_info: induction_record.training_provider_info&.delivery_partner_info,
      schedule_info: induction_record.schedule_info,
      contract_period_year: induction_record.cohort_year,
      created_at: induction_record.created_at,
      ecf_start_induction_record_id: induction_record.induction_record_id,
      school_urn: induction_record.school_urn
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

  # ==========================================================================
  # DataFixes logic - corrections for ECF1 data quality issues
  # ==========================================================================

  # Corrects start dates for induction records
  # - For first IR: if start_date == 2022-02-09 (when IRs were added), use 2021-09-01
  # - Otherwise use min of start_date and created_at
  # - For subsequent records: just use start_date
  def corrected_start_date(induction_record, sequence_number)
    if sequence_number.zero?
      if induction_record.start_date.to_date == INDUCTION_RECORDS_ADDED_DATE
        SERVICE_START_DATE
      else
        [induction_record.start_date, induction_record.created_at.to_date].min
      end
    else
      induction_record.start_date
    end
  end

  # Corrects end dates for school periods (ECTAtSchoolPeriod/MentorAtSchoolPeriod)
  def corrected_end_date(induction_record, induction_records, participant_type:)
    if participant_type == :ect && ect_with_more_than_2_irs_and_completion_date?(induction_records)
      if last_created_induction_record?(induction_record, induction_records)
        return ect_induction_completion_date
      end

      return [induction_record.end_date, ect_induction_completion_date].compact.min
    end

    return induction_record.updated_at.to_date if last_and_leaving_and_flipping_dates?(induction_record, induction_records)
    return first_created_induction_record(induction_records).updated_at.to_date if two_induction_records_and_last_completed?(induction_records)

    induction_record.end_date
  end

  # Corrects end dates for training periods
  def corrected_training_period_end_date(induction_record, induction_records, participant_type:)
    candidate_end_date = induction_record.end_date

    return first_created_induction_record(induction_records).end_date if two_irs_at_a_school_and_only_last_deferred_or_withdrawn?(induction_records)
    return candidate_end_date if induction_records.count > 1
    return candidate_end_date if participant_type == :ect
    return candidate_end_date if candidate_end_date.present?
    return unless participant_type == :mentor

    date_for_mentors_with_one_ir(induction_record)
  end

  # For mentors with a single IR and no end date:
  # - If mentor has completion_date < 1/9/2021, use 31 August following start_date
  # - If mentor has completion_date >= 1/9/2021, use 31 August following completion_date
  def date_for_mentors_with_one_ir(induction_record)
    return if mentor_completion_date.blank?
    return the_31st_august_following(induction_record.start_date) if mentor_completion_date < SERVICE_START_DATE

    the_31st_august_following(mentor_completion_date)
  end

  # ==========================================================================
  # DataFixes helper methods
  # ==========================================================================

  def ect_with_more_than_2_irs_and_completion_date?(induction_records)
    return false unless induction_records.count > 2

    ect_induction_completion_date.present?
  end

  def ect_induction_completion_date
    ecf1_teacher_history.ect&.induction_completion_date
  end

  def first_created_induction_record(induction_records)
    induction_records.min_by(&:created_at)
  end

  def last_created_induction_record(induction_records)
    induction_records.max_by(&:created_at)
  end

  def last_created_induction_record?(induction_record, induction_records)
    induction_record.induction_record_id == last_created_induction_record(induction_records).induction_record_id
  end

  def last_and_leaving_and_flipping_dates?(induction_record, induction_records)
    last_created_induction_record?(induction_record, induction_records) &&
      leaving?(induction_record) &&
      flipped_dates?(induction_record)
  end

  def two_induction_records?(induction_records)
    induction_records.count == 2
  end

  def two_induction_records_and_last_completed?(induction_records)
    two_induction_records?(induction_records) && completed?(last_created_induction_record(induction_records))
  end

  def two_irs_at_a_school_and_only_last_deferred_or_withdrawn?(induction_records)
    return false unless two_induction_records?(induction_records)

    first_induction_record = first_created_induction_record(induction_records)
    second_induction_record = last_created_induction_record(induction_records)

    return false if deferred?(first_induction_record)
    return false if withdrawn?(first_induction_record)

    deferred?(second_induction_record) || withdrawn?(second_induction_record)
  end

  # Induction record status helpers
  def leaving?(induction_record)
    induction_record.induction_status == "leaving"
  end

  def completed?(induction_record)
    induction_record.induction_status == "completed"
  end

  def deferred?(induction_record)
    induction_record.training_status == "deferred"
  end

  def withdrawn?(induction_record)
    induction_record.training_status == "withdrawn"
  end

  def flipped_dates?(induction_record)
    return false if induction_record.start_date.blank? || induction_record.end_date.blank?

    induction_record.start_date > induction_record.end_date
  end
end
