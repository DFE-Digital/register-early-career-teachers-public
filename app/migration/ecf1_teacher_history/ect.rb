class ECF1TeacherHistory::ECT
  using Migration::CompactWithIgnore

  attr_reader :participant_profile_id,
              :created_at,
              :updated_at,
              :induction_start_date,
              :induction_completion_date,
              :pupil_premium_uplift,
              :sparsity_uplift,
              :payments_frozen_cohort_start_year,
              :states

  attr_accessor :induction_records, :mentor_at_school_periods

  def initialize(participant_profile_id:, created_at:, updated_at:, induction_start_date:, induction_completion_date:, pupil_premium_uplift:, sparsity_uplift:, payments_frozen_cohort_start_year:, states:, induction_records:, mentor_at_school_periods:)
    @participant_profile_id = participant_profile_id
    @created_at = created_at
    @updated_at = updated_at
    @induction_start_date = induction_start_date
    @induction_completion_date = induction_completion_date
    @pupil_premium_uplift = pupil_premium_uplift
    @sparsity_uplift = sparsity_uplift
    @payments_frozen_cohort_start_year = payments_frozen_cohort_start_year
    @states = states
    @induction_records = induction_records
    @mentor_at_school_periods = mentor_at_school_periods
  end

  def self.from_hash(hash)
    hash.compact_with_ignore!

    hash[:induction_records] = hash[:induction_records]&.map { ECF1TeacherHistory::InductionRecord.from_hash(it) } || []
    hash[:mentor_at_school_periods] = hash[:mentor_at_school_periods]&.map { ECF1TeacherHistory::MentorAtSchoolPeriod.from_hash(it) } || []
    hash[:states] = hash[:states]&.map { ECF1TeacherHistory::ProfileState.from_hash(it) } || []

    new(**FactoryBot.attributes_for(:ecf1_teacher_history_ect, **hash))
  end
end
