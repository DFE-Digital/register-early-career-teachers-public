RSpec.describe Schools::Mentors::ChangeEmailAddressWizard::StateStore do
  subject(:state_store) do
    described_class.new(mentor_at_school_period:)
  end

  let(:school) { FactoryBot.create(:school) }
  let(:mentor_at_school_period) do
    FactoryBot.create(:mentor_at_school_period, school:, email: "mentor@example.com")
  end

  describe "#email" do
    it "uses the mentor's current email when no new email is stored" do
      expect(state_store.email).to eq("mentor@example.com")
    end

    it "prefers the saved email" do
      state_store.write(email: "new_email@example.com")

      expect(state_store.email).to eq("new_email@example.com")
    end
  end

  describe "mentor-specific session state" do
    it "does not share a saved email with another mentor's wizard" do
      state_store.write(email: "new_email@example.com")
      other_mentor = FactoryBot.create(:mentor_at_school_period, school:, email: "other@example.com")
      other_state_store = described_class.new(mentor_at_school_period: other_mentor)

      expect(other_state_store.email).to eq("other@example.com")
    end
  end
end
