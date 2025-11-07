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

  describe "declarative touch" do
    let(:teacher) { FactoryBot.create(:teacher) }
    let(:instance) { FactoryBot.create(:teacher_id_change, teacher:) }

    context "target teacher" do
      let(:target) { teacher }

      it_behaves_like "a declarative touch model", on_event: %i[create destroy], timestamp_attribute: :api_updated_at
    end
  end
end
