class TeacherHistoryConverter
  def initialize(ecf1_teacher_history:)
    @ecf1_teacher_history = ecf1_teacher_history
  end

  def convert_to_ecf2!
    ECF2TeacherHistory.new(teacher_row:, ect_at_school_period_rows:)
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
    @ecf1_teacher_history.ect.induction_records.map do |induction_record|
      ECF2TeacherHistory::ECTAtSchoolPeriodRow.new(
        **induction_record_attributes(induction_record),
        training_period_rows: [
          ECF2TeacherHistory::TrainingPeriodRow.new(**training_period_attributes(induction_record))
        ]
      )
    end
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
      training_programme: ecf2_training_programme(induction_record.training_programme)
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
end
