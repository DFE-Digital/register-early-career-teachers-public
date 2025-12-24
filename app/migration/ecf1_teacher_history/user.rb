ECF1TeacherHistory::User = Struct.new(:trn, :full_name, :user_id, :created_at, :updated_at, keyword_init: true) do
  def self.from_hash(hash)
    new(FactoryBot.attributes_for(:ecf1_teacher_history_user, **hash))
  end
end
