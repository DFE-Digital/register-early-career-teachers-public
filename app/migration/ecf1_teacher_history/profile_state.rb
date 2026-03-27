ECF1TeacherHistory::ProfileState = Struct.new(:state, :reason, :created_at, :cpd_lead_provider_id, keyword_init: true) do
  def self.from_hash(hash)
    FactoryBot.build(:ecf1_teacher_history_profile_state_row, **hash.compact)
  end

  def lead_provider_id
    Mappers::LeadProviderMapper.new(index_by: :cpd_lead_provider_id).get(cpd_lead_provider_id)&.id
  end

  def created_on
    created_at&.to_date
  end
end
