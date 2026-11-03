RSpec.describe Admin::Teachers::UndoRegistrationWizard::Steps::ConfirmStep do
  subject(:step) { described_class.new(wizard:, **attributes) }

  let(:wizard) do
    instance_double(Admin::Teachers::UndoRegistrationWizard::Wizard, periods_will_be_closed?: periods_will_be_closed)
  end
  let(:periods_will_be_closed) { false }
  let(:attributes) do
    {
      confirmed: "1",
      expected_action: "delete",
      expected_training_period_ids: [""],
      expected_mentorship_period_ids: [""],
      expected_at_school_period_gid: "gid://app/ECTAtSchoolPeriod/5"
    }
  end

  it { is_expected.to be_valid }

  %i[expected_training_period_ids expected_mentorship_period_ids expected_at_school_period_gid].each do |attribute|
    it "requires #{attribute} to have been reviewed" do
      attributes.delete(attribute)

      expect(step).not_to be_valid
      expect(step.errors[:base]).to contain_exactly("Review the periods to undo before confirming")
    end
  end

  it "rejects an unsupported action" do
    attributes[:expected_action] = "archive"

    expect(step).not_to be_valid
    expect(step).to have_error(:expected_action)
  end

  context "when the confirmation is not selected" do
    before { attributes[:confirmed] = "0" }

    it "requires confirmation of the deletion" do
      expect(step).not_to be_valid
      expect(step.errors[:confirmed]).to contain_exactly("Confirm you want to undo this registration and delete this school period")
    end

    context "when the periods would be closed" do
      let(:periods_will_be_closed) { true }

      it "requires confirmation of the closure" do
        expect(step).not_to be_valid
        expect(step.errors[:confirmed]).to contain_exactly("Confirm you want to undo this registration and close this school period")
      end
    end
  end

  context "when the expected action is missing" do
    before { attributes.delete(:expected_action) }

    it "is invalid" do
      expect(step).not_to be_valid
      expect(step).to have_error(:expected_action)
    end
  end
end
