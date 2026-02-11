class ECF2TeacherHistory::MentorshipPeriod
  attr_reader :started_on,
              :finished_on,
              :ecf_start_induction_record_id,
              :ecf_end_induction_record_id,
              :mentor_at_school_period_id,
              :api_ect_training_record_id,
              :api_mentor_training_record_id

  def initialize(started_on:,
                 finished_on:,
                 ecf_start_induction_record_id:,
                 ecf_end_induction_record_id:,
                 mentor_at_school_period_id:,
                 api_ect_training_record_id:,
                 api_mentor_training_record_id:)
    @started_on = started_on
    @finished_on = finished_on
    @ecf_start_induction_record_id = ecf_start_induction_record_id
    @ecf_end_induction_record_id = ecf_end_induction_record_id
    @mentor_at_school_period_id = mentor_at_school_period_id
    @api_ect_training_record_id = api_ect_training_record_id
    @api_mentor_training_record_id = api_mentor_training_record_id
  end

  def to_h
    {
      started_on:,
      finished_on:,
      ecf_start_induction_record_id:,
      ecf_end_induction_record_id:,
      mentor_at_school_period_id:
    }
  end
  alias_method :to_hash, :to_h

  def summary = "<#{[ecf_start_induction_record_id, ecf_end_induction_record_id, api_mentor_training_record_id, started_on, finished_on].join(': ')}>"
end
