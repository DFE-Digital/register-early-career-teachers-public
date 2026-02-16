ECF1TeacherHistory::ProfileState = Struct.new(:state, :reason, :created_at, :cpd_lead_provider_id, keyword_init: true) do
  def self.from_hash(hash)
    FactoryBot.build(:ecf1_teacher_history_profile_state_row, **hash.compact)
  end
end
