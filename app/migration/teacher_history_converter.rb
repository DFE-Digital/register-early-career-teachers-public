class TeacherHistoryConverter
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
      trn: @ecf1_teacher_history.user.trn,
      trnless: @ecf1_teacher_history.user.trn.blank?,
      trs_first_name: parsed_name.first_name,
      trs_last_name: parsed_name.last_name,
      api_id: @ecf1_teacher_history.user.user_id,
      api_ect_training_record_id: @ecf1_teacher_history.ect&.participant_profile_id,
      api_mentor_training_record_id: @ecf1_teacher_history.mentor&.participant_profile_id,
      api_updated_at: calculate_api_updated_at,
      ect_pupil_premium_uplift: @ecf1_teacher_history.ect&.pupil_premium_uplift,
      ect_sparsity_uplift: @ecf1_teacher_history.ect&.sparsity_uplift,
      ect_payments_frozen_year: @ecf1_teacher_history.ect&.payments_frozen_cohort_start_year,
      mentor_payments_frozen_year: @ecf1_teacher_history.mentor&.payments_frozen_cohort_start_year,
      created_at: @ecf1_teacher_history.user.created_at,
      updated_at: @ecf1_teacher_history.user.updated_at
    )
  end

  # Calculates the api_updated_at timestamp using ECF's ParticipantSerializer logic:
  # The max of participant_profiles.updated_at, user.updated_at,
  # participant_identities.updated_at, and induction_records.updated_at
  def calculate_api_updated_at
    timestamps = [@ecf1_teacher_history.user.updated_at]

    if @ecf1_teacher_history.ect.present?
      timestamps << @ecf1_teacher_history.ect.updated_at
      timestamps.concat(@ecf1_teacher_history.ect.induction_records.map(&:updated_at))
    end

    if @ecf1_teacher_history.mentor.present?
      timestamps << @ecf1_teacher_history.mentor.updated_at
      timestamps.concat(@ecf1_teacher_history.mentor.induction_records.map(&:updated_at))
    end

    # participant_identities.updated_at is captured in user if needed
    timestamps.concat(@ecf1_teacher_history.participant_identity_updated_ats || [])

    timestamps.compact.max
  end

  def ect_at_school_period_rows
    return [] if @ecf1_teacher_history.ect.blank?

    @ecf1_teacher_history.ect.induction_records.map do |induction_record|
      ECF2TeacherHistory::ECTAtSchoolPeriodRow.new(
        **induction_record_attributes(induction_record),
        training_period_rows: [
          ECF2TeacherHistory::TrainingPeriodRow.new(**training_period_attributes(induction_record), is_ect: true)
        ]
      )
    end
  end

  def mentor_at_school_period_rows
    return [] if @ecf1_teacher_history.mentor.blank?

    @ecf1_teacher_history.mentor.induction_records.map do |induction_record|
      ECF2TeacherHistory::MentorAtSchoolPeriodRow.new(
        **mentor_induction_record_attributes(induction_record),
        training_period_rows: build_mentor_training_period_rows(induction_record)
      )
    end
  end

  def mentor_induction_record_attributes(induction_record)
    {
      started_on: period_started_on(induction_record),
      finished_on: induction_record.end_date,
      school: Types::SchoolData.new(urn: induction_record.school_urn, name: nil),
      email: induction_record.preferred_identity_email
    }
  end

  def build_mentor_training_period_rows(induction_record)
    # Mentors only have training periods for provider_led training
    training_programme = ecf2_training_programme(induction_record.training_programme)
    return [] unless training_programme == "provider_led"

    [ECF2TeacherHistory::TrainingPeriodRow.new(**mentor_training_period_attributes(induction_record))]
  end

  def mentor_training_period_attributes(induction_record)
    base_attributes = training_period_attributes(induction_record)

    # Handle mentor completion date logic for single induction record with no end date
    if base_attributes[:finished_on].blank? && single_mentor_induction_record? && mentor_completion_date.present?
      base_attributes[:finished_on] = mentor_training_period_end_date(induction_record)
    end

    base_attributes
  end

  def single_mentor_induction_record?
    @ecf1_teacher_history.mentor&.induction_records&.count == 1
  end

  def mentor_completion_date
    @ecf1_teacher_history.mentor&.mentor_completion_date
  end

  # Logic from DataFixes module:
  # If completion_date < 1/9/2021, use 31 August following start_date
  # If completion_date >= 1/9/2021, use 31 August following completion_date
  def mentor_training_period_end_date(induction_record)
    service_start_date = Date.new(2021, 9, 1)

    if mentor_completion_date < service_start_date
      the_31st_august_following(period_started_on(induction_record))
    else
      the_31st_august_following(mentor_completion_date)
    end
  end

  def the_31st_august_following(date)
    year = date.month > 8 ? date.year + 1 : date.year
    Date.new(year, 8, 31)
  end

  def induction_record_attributes(induction_record)
    {
      started_on: period_started_on(induction_record),
      finished_on: induction_record.end_date,
      school: Types::SchoolData.new(urn: induction_record.school_urn, name: "Thing"),
      email: induction_record.preferred_identity_email,
      mentorship_period_rows: [],
      training_period_rows: [],
      appropriate_body: induction_record.appropriate_body
    }
  end

  def training_period_attributes(induction_record)
    {
      started_on: period_started_on(induction_record),
      finished_on: induction_record.end_date,
      training_programme: ecf2_training_programme(induction_record.training_programme),
      **deferral_attributes(induction_record),
      **withdrawal_attributes(induction_record),
      lead_provider_info: induction_record.training_provider_info&.lead_provider_info,
      delivery_partner_info: induction_record.training_provider_info&.delivery_partner_info,
      schedule_info: induction_record.schedule_info,
      contract_period: induction_record.cohort_year,
      created_at: induction_record.created_at,
      ecf_start_induction_record_id: induction_record.induction_record_id
    }
  end

  def parsed_name
    @parsed_name ||= Teachers::FullNameParser.new(full_name: @ecf1_teacher_history.user.full_name)
  end

  def period_started_on(induction_record)
    [induction_record.start_date, induction_record.created_at.to_date].min
  end

  def ecf1_events
    @ecf1_teacher_history.induction_records.map do |ir|
      # build some kind of chronological representation of
      # what happened
    end
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
end
