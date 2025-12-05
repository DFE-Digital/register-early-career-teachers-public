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
    @ecf1_teacher_history.ect.induction_records.map do |ir|
      ECF2TeacherHistory::ECTAtSchoolPeriodRow.new(
        started_on: period_started_on(ir),
        finished_on: ir.end_date,
        school: Types::SchoolData.new(urn: ir.school_urn, name: "Thing"),
        email: ir.preferred_identity_email,
        mentorship_period_rows: [],
        training_period_rows: [],
        appropriate_body: nil
      )
    end
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
end
