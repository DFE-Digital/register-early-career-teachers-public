class ECF1TeacherHistory::Mentor
  using Migration::CompactWithIgnore

  attr_reader :participant_profile_id,
              :created_at,
              :updated_at,
              :mentor_completion_date,
              :mentor_completion_reason,
              :payments_frozen_cohort_start_year,
              :states,
              :ero_mentor,
              :ero_declarations

  attr_accessor :induction_records

  def initialize(participant_profile_id:, created_at:, updated_at:, mentor_completion_date:, mentor_completion_reason:, payments_frozen_cohort_start_year:, states:, induction_records:, ero_mentor:, ero_declarations:)
    @participant_profile_id = participant_profile_id
    @created_at = created_at
    @updated_at = updated_at
    @mentor_completion_date = mentor_completion_date
    @mentor_completion_reason = mentor_completion_reason
    @payments_frozen_cohort_start_year = payments_frozen_cohort_start_year
    @states = states
    @induction_records = induction_records
    @ero_mentor = ero_mentor
    @ero_declarations = ero_declarations
  end

  def self.from_hash(hash)
    hash.compact_with_ignore!

    hash[:induction_records] = hash[:induction_records]&.map { ECF1TeacherHistory::InductionRecord.from_hash(it) } || []
    hash[:states] = hash[:states]&.map { ECF1TeacherHistory::ProfileState.from_hash(it) } || []

    new(**FactoryBot.attributes_for(:ecf1_teacher_history_mentor, **hash))
  end
end
