ECF1TeacherHistory::InductionRecord = Struct.new(
  :induction_record_id,
  :start_date,
  :end_date,
  :created_at,
  :updated_at,
  :cohort_year,
  :school_urn,
  :schedule_info,
  :preferred_identity_email,
  :mentor_profile_id,
  :training_status,
  :induction_status,
  :training_programme,
  :training_provider_info,
  :appropriate_body,
  keyword_init: true
) do
  using Migration::CompactWithIgnore

  def self.from_hash(hash)
    hash.compact_with_ignore!

    if (training_provider_info = hash[:training_provider_info])
      hash[:training_provider_info] = ECF1TeacherHistory::TrainingProviderInfo.new(training_provider_info)
    end

    new(FactoryBot.attributes_for(:ecf1_teacher_history_induction_record_row, **hash))
  end
end
