class ECF2TeacherHistory
  class InvalidPeriodType < StandardError; end

  ECTAtSchoolPeriodRow = Struct.new(:started_on, :finished_on, :mentorship_period_rows, :training_period_rows)
  MentorAtSchoolPeriodRow = Struct.new(:started_on, :finished_on, :mentorship_period_rows)
  TrainingPeriodRow = Struct.new(:started_on, :finished_on)
  MentorshipPeriodRow = Struct.new(:started_on, :finished_on)

  attr_reader :trn,
              :trs_first_name,
              :trs_last_name,
              :corrected_name,
              :ect_at_school_period_rows,
              :mentor_at_school_period_rows,
              :training_period_rows,
              :mentorship_period_rows

  def initialize(
    trn:,
    trs_first_name:,
    trs_last_name:,
    corrected_name:,
    ect_at_school_period_rows: [],
    mentor_at_school_period_rows: []
  )
    @trn = trn
    @trs_first_name = trs_first_name
    @trs_last_name = trs_last_name
    @corrected_name = corrected_name

    @ect_at_school_period_rows = ect_at_school_period_rows
    @mentor_at_school_period_rows = mentor_at_school_period_rows
  end

  def save_all!
  end
end
