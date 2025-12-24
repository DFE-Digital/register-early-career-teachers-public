ECF1TeacherHistory::ECT = Struct.new(
  :participant_profile_id,
  :migration_mode,
  :created_at,
  :updated_at,
  :induction_start_date,
  :induction_completion_date,
  :pupil_premium_uplift,
  :sparsity_uplift,
  :payments_frozen_cohort_start_year,
  :states,
  :induction_records,
  keyword_init: true
) do
  using Migration::CompactWithIgnore

  def self.from_hash(hash)
    hash.compact_with_ignore!

    hash[:induction_records] = hash[:induction_records].map { ECF1TeacherHistory::InductionRecord.from_hash(it) }

    new(FactoryBot.attributes_for(:ecf1_teacher_history_ect, **hash))
  end
end
