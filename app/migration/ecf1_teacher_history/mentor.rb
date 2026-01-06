class ECF1TeacherHistory::Mentor
  using Migration::CompactWithIgnore

  attr_reader :participant_profile_id,
              :created_at,
              :updated_at,
              :mentor_completion_date,
              :mentor_completion_reason,
              :payments_frozen_cohort_start_year,
              :states

  def initialize(participant_profile_id:, migration_mode:, created_at:, updated_at:, mentor_completion_date:, mentor_completion_reason:, payments_frozen_cohort_start_year:, states:, induction_records:)
    @participant_profile_id = participant_profile_id
    @migration_mode = migration_mode
    @created_at = created_at
    @updated_at = updated_at
    @mentor_completion_date = mentor_completion_date
    @mentor_completion_reason = mentor_completion_reason
    @payments_frozen_cohort_start_year = payments_frozen_cohort_start_year
    @states = states
    @induction_records = induction_records
  end

  def self.from_hash(hash)
    hash.compact_with_ignore!

    hash[:induction_records] = hash[:induction_records]&.map { ECF1TeacherHistory::InductionRecord.from_hash(it) } || []
    hash[:states] = hash[:states]&.map { ECF1TeacherHistory::ProfileState.from_hash(it) } || []

    new(**FactoryBot.attributes_for(:ecf1_teacher_history_mentor, **hash))
  end

private

  def induction_records(migration_mode: :economy)
    case migration_mode
    when :premium then premium_induction_records
    when :economy then economy_induction_records
    else fail "Invalid mode"
    end
  end

  def premium_induction_records
    @induction_records
  end

  def economy_induction_records
    @induction_records
  end
end
