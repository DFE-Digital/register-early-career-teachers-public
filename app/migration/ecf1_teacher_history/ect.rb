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

  attr_writer :induction_records

  def initialize(participant_profile_id:, created_at:, updated_at:, induction_start_date:, induction_completion_date:, pupil_premium_uplift:, sparsity_uplift:, payments_frozen_cohort_start_year:, states:, induction_records:)
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
  end

  def self.from_hash(hash)
    hash.compact_with_ignore!

    hash[:induction_records] = hash[:induction_records]&.map { ECF1TeacherHistory::InductionRecord.from_hash(it) } || []
    hash[:states] = hash[:states]&.map { ECF1TeacherHistory::ProfileState.from_hash(it) } || []

    new(**FactoryBot.attributes_for(:ecf1_teacher_history_ect, **hash))
  end

  def induction_records(migration_mode: :latest_induction_records)
    case migration_mode
    when :all_induction_records then all_induction_records
    when :latest_induction_records then latest_induction_records
    else fail "Invalid mode"
    end
  end

private

  def all_induction_records
    @induction_records
  end

  def latest_induction_records
    @induction_records

    # row_matches = ->(rows, row) do
    #   rows.any? do |r|
    #     [r.training_provider_info&.lead_provider_info&.ecf1_id, r.school.urn, r.cohort_year] ==
    #       [row.training_provider_info&.lead_provider_info&.ecf1_id, row.school.urn, row.cohort_year]
    #   end
    # end

    # if migration_mode == "latest_induction_records"
    #   rows.reverse.each_with_object([]) do |row, result|
    #     result.unshift(row) unless row_matches.call(result, row)
    #   end
    # else
    #   rows
    # end
  end
end
