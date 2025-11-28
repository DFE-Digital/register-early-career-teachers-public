class ECF2TeacherHistory
  class InvalidPeriodType < StandardError; end

  TeacherRow = Struct.new(
    :trn,
    :trnless,
    :trs_first_name,
    :trs_last_name,
    :corrected_name,

    :api_id,
    :api_ect_training_record_id,
    :api_mentor_training_record_id,
    :api_updated_at,

    :ect_pupil_premium_uplift,
    :ect_sparsity_uplift,
    :ect_first_became_eligible_for_training_at,
    :ect_payments_frozen_year,

    :mentor_became_ineligible_for_funding_on,
    :mentor_became_ineligible_for_funding_reason,
    :mentor_first_became_eligible_for_training_at,
    :mentor_payments_frozen_year
  ) do
    def to_hash
      override_trnless = trnless || false

      {
        trn:,
        trs_first_name:,
        trs_last_name:,
        trnless: override_trnless,
        corrected_name:,

        api_id:,
        api_ect_training_record_id:,
        api_mentor_training_record_id:,

        ect_pupil_premium_uplift:,
        ect_sparsity_uplift:,
        ect_first_became_eligible_for_training_at:,
        ect_payments_frozen_year:,

        mentor_became_ineligible_for_funding_on:,
        mentor_became_ineligible_for_funding_reason:,
        mentor_first_became_eligible_for_training_at:,
        mentor_payments_frozen_year:
      }
    end
  end

  ECTAtSchoolPeriodRow = Struct.new(:started_on, :finished_on, :mentorship_period_rows, :training_period_rows)
  MentorAtSchoolPeriodRow = Struct.new(:started_on, :finished_on, :mentorship_period_rows)
  TrainingPeriodRow = Struct.new(:started_on, :finished_on)
  MentorshipPeriodRow = Struct.new(:started_on, :finished_on)

  attr_reader :teacher_row,
              :ect_at_school_period_rows,
              :mentor_at_school_period_rows,
              :training_period_rows,
              :mentorship_period_rows

  def initialize(teacher_row:, ect_at_school_period_rows: [], mentor_at_school_period_rows: [])
    @teacher_row = teacher_row

    @ect_at_school_period_rows = ect_at_school_period_rows
    @mentor_at_school_period_rows = mentor_at_school_period_rows
  end

  def save_all!
    Teacher.create!(**teacher_row)
  end
end
