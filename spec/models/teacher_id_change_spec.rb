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
    let(:instance) { FactoryBot.create(:teacher_id_change) }

    def will_change_attribute(attribute_to_change:, new_value:)
      case attribute_to_change
      when :api_from_teacher_id, :api_to_teacher_id
        FactoryBot.create(:teacher, api_id: new_value)
      end
    end

    context "target teacher" do
      let(:target) { instance.teacher }

      it_behaves_like "a declarative touch model", when_changing: %i[api_from_teacher_id api_to_teacher_id], timestamp_attribute: :api_updated_at
    end
  end
end
