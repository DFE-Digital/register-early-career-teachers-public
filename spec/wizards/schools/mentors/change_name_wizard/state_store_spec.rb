RSpec.describe Schools::Mentors::ChangeNameWizard::StateStore do
  subject(:state_store) { described_class.new(mentor_at_school_period:) }

  let(:school) { FactoryBot.create(:school) }
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:teacher) { FactoryBot.create(:teacher, trs_first_name: "Terry", trs_last_name: "Pratchett") }
  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, school:, teacher:) }

  describe "name" do
    it "returns the new name" do
      state_store.write(name: "Terry Smith")

      expect(state_store.name).to eq("Terry Smith")
    end

    it "defaults to the mentor's name" do
      expect(state_store.name).to eq("Terry Pratchett")
    end
  end

  describe "old_name" do
    it "defaults to the mentor's current name" do
      expect(state_store.old_name).to eq("Terry Pratchett")
    end

    it "returns the stored original name after the teacher's name changes" do
      state_store.write(old_name: "Terry Pratchett")
      teacher.update!(corrected_name: "Terry Smith")

      expect(state_store.old_name).to eq("Terry Pratchett")
    end
  end

  describe "mentor-specific session state" do
    it "uses the other mentor's name instead of sharing saved state" do
      state_store.write(name: "Terry Pratchett")
      other_teacher = FactoryBot.create(:teacher, trs_first_name: "Sam", trs_last_name: "Vimes")
      other_mentor = FactoryBot.create(:mentor_at_school_period, school:, teacher: other_teacher)
      other_state_store = described_class.new(mentor_at_school_period: other_mentor)

      expect(other_state_store.name).to eq("Sam Vimes")
    end
  end
end
