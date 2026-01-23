class ECF2TeacherHistory::MentorshipPeriod
  attr_reader :started_on,
              :finished_on,
              :ecf_start_induction_record_id,
              :ecf_end_induction_record_id,
              :mentor_data

  def initialize(started_on:, finished_on:, ecf_start_induction_record_id:, ecf_end_induction_record_id:, mentor_data:)
    @started_on = started_on
    @finished_on = finished_on
    @ecf_start_induction_record_id = ecf_start_induction_record_id
    @ecf_end_induction_record_id = ecf_end_induction_record_id
    @mentor_data = mentor_data
  end

  def to_hash
    { started_on:, finished_on:, ecf_start_induction_record_id:, ecf_end_induction_record_id: }
  end

  def mentor_teacher
    ::Teacher.find_by(trn: mentor_data.trn)
  end

  def mentor_at_school_period
    {
      # FIXME: use dates too to ensure we pick the right mentorship period, it's feasible
      #        that one teacher has multiple at the same school
      mentor: ::MentorAtSchoolPeriod
        .joins(:school, :teacher)
        .find_by(school: { urn: mentor_data.urn }, teacher: { trn: mentor_data.trn })
    }
  end
end
