RSpec.describe Schools::RegisterECTWizardHelper, type: :helper do
  describe "#appropriate_body_change_path" do
    subject { helper.appropriate_body_change_path(school) }

    context "when the school is independent" do
      let(:school) { double("School", independent?: true) }

      it "returns the independent school appropriate body path" do
        expect(subject).to eq(
          schools_register_ect_wizard_change_independent_school_appropriate_body_path
        )
      end
    end

    context "when the school is not independent" do
      let(:school) { double("School", independent?: false) }

      it "returns the state school appropriate body path" do
        expect(subject).to eq(
          schools_register_ect_wizard_change_state_school_appropriate_body_path
        )
      end
    end

    context "when the school is nil" do
      let(:school) { nil }

      it "returns the state school appropriate body path by default" do
        expect(subject).to eq(
          schools_register_ect_wizard_change_state_school_appropriate_body_path
        )
      end
    end
  end
end
