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
      trs_first_name: parsed_name.first_name,
      trs_last_name: parsed_name.last_name,
      api_id: @ecf1_teacher_history.user.user_id,
      created_at: @ecf1_teacher_history.user.created_at,
      updated_at: @ecf1_teacher_history.user.updated_at
    )
  end

  def ect_at_school_period_rows
    return [] unless @ecf1_teacher_history.ect

    @ecf1_teacher_history.ect.induction_records.map do |induction_record|
      ECF2TeacherHistory::ECTAtSchoolPeriodRow.new(
        **induction_record_attributes(induction_record),
        training_period_rows: [
          ECF2TeacherHistory::TrainingPeriodRow.new(**training_period_attributes(induction_record))
        ]
      )
    end
  end

  def mentor_at_school_period_rows
    return [] unless @ecf1_teacher_history.mentor

    mentor = @ecf1_teacher_history.mentor

    # If mentor has induction records, convert those
    if mentor.induction_records.any?
      return mentor.induction_records.map do |induction_record|
        ECF2TeacherHistory::MentorAtSchoolPeriodRow.new(
          **mentor_induction_record_attributes(induction_record),
          training_period_rows: [
            ECF2TeacherHistory::TrainingPeriodRow.new(**training_period_attributes(induction_record))
          ]
        )
      end
    end

    # ERO mentor: no induction records but has declaration data
    return [] unless mentor.ero_declaration

    [ero_mentor_at_school_period_row(mentor)]
  end

  def mentor_induction_record_attributes(induction_record)
    {
      started_on: period_started_on(induction_record),
      finished_on: induction_record.end_date,
      school: Types::SchoolData.new(urn: induction_record.school_urn, name: "Thing"),
      email: induction_record.preferred_identity_email,
      training_period_rows: []
    }
  end

  def ero_mentor_at_school_period_row(mentor)
    ero_declaration = mentor.ero_declaration
    start_date = calculate_ero_mentor_start_date(mentor, ero_declaration)
    end_date = calculate_ero_mentor_end_date(mentor, ero_declaration)

    ECF2TeacherHistory::MentorAtSchoolPeriodRow.new(
      started_on: start_date,
      finished_on: end_date,
      school: Types::SchoolData.new(urn: ero_declaration.school_urn, name: "Thing"),
      email: ero_declaration.preferred_identity_email,
      training_period_rows: [
        ECF2TeacherHistory::TrainingPeriodRow.new(**ero_mentor_training_period_attributes(mentor, ero_declaration, start_date, end_date))
      ]
    )
  end

  def ero_mentor_training_period_attributes(mentor, ero_declaration, start_date, end_date)
    {
      started_on: start_date,
      finished_on: end_date,
      created_at: mentor.created_at,
      training_programme: "provider_led",
      lead_provider_info: ero_declaration.training_provider_info.lead_provider_info,
      delivery_partner_info: ero_declaration.training_provider_info.delivery_partner_info,
      schedule_info: nil, # ERO mentors use ecf-standard-september schedule, looked up by cohort_year
      contract_period: ero_declaration.cohort_year
    }
  end

  def calculate_ero_mentor_start_date(mentor, ero_declaration)
    # Use the earliest of: declaration date, profile created_at, or service start (2021-09-01)
    service_start = Date.new(2021, 9, 1)
    [ero_declaration.declaration_date.to_date, mentor.created_at.to_date, service_start].min
  end

  def calculate_ero_mentor_end_date(mentor, ero_declaration)
    # If mentor has completion date, use 31 August following that date
    # Otherwise use 31 August following the declaration date
    reference_date = mentor.mentor_completion_date || ero_declaration.declaration_date.to_date
    the_31st_august_following(reference_date)
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
      lead_provider_info: induction_record.training_provider_info.lead_provider_info,
      delivery_partner_info: induction_record.training_provider_info.delivery_partner_info,
      schedule_info: induction_record.schedule_info,
      # FIXME: rename this to contract_period_year
      contract_period: induction_record.cohort_year,
      created_at: induction_record.created_at
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
