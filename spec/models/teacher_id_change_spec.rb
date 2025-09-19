describe TeacherIdChange do
  describe "associations" do
    it { is_expected.to belong_to(:teacher) }
  end

  describe "validations" do
    subject { FactoryBot.create(:teacher_id_change) }

    it { is_expected.to validate_presence_of(:teacher) }
    it { is_expected.to validate_presence_of(:api_from_teacher_id) }
    it { is_expected.to validate_presence_of(:api_to_teacher_id) }
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive.with_message("ECF id already exists for another teacher id change").allow_nil }
  end
end
