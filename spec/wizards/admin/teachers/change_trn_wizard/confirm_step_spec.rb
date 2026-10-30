RSpec.describe Admin::Teachers::ChangeTRNWizard::ConfirmStep do
  subject(:step) do
    described_class.new(confirmed:, expected_trn:, wizard:)
  end

  let(:merge_proposed) { false }
  let(:confirmation_message) { "Confirm you want to change this teacher’s TRN" }
  let(:confirmed) { "1" }
  let(:expected_trn) { "2345678" }
  let(:store) { FactoryBot.build(:session_repository) }
  let(:wizard) do
    instance_double(Admin::Teachers::ChangeTRNWizard::Wizard, store:, update!: true, merge_proposed?: merge_proposed)
  end

  before do
    store.trn = "2345678"
  end

  describe "#save!" do
    it "updates the proposed records through the wizard" do
      expect(wizard).to receive(:update!).with(no_args)

      expect(step.save!).to be(true)
    end

    context "when confirmation is not selected" do
      let(:confirmed) { "0" }

      it "does not update the records" do
        expect(wizard).not_to receive(:update!)

        expect(step.save!).to be(false)
        expect(step.errors[:confirmed]).to contain_exactly(
          confirmation_message
        )
        expect(store.records_processed).to be_nil
      end
    end

    context "when confirmation is missing" do
      let(:confirmed) { nil }

      it "does not update the records" do
        expect(wizard).not_to receive(:update!)

        expect(step.save!).to be(false)
        expect(step.errors[:confirmed]).to contain_exactly(
          confirmation_message
        )
        expect(store.records_processed).to be_nil
      end
    end

    context "when the proposed TRN has changed" do
      let(:expected_trn) { "3456789" }

      it "rejects confirmation without updating the records" do
        expect(wizard).not_to receive(:update!)

        expect { step.save! }.to raise_error(described_class::ProposedTRNChangedError)
      end
    end

    context "when the reviewed TRN is missing" do
      let(:expected_trn) { nil }

      it "rejects confirmation without updating the records" do
        expect(wizard).not_to receive(:update!)

        expect { step.save! }.to raise_error(described_class::ProposedTRNChangedError)
      end
    end

    context "when the wizard rejects the update" do
      before do
        allow(wizard).to receive(:update!)
          .and_raise(Admin::Teachers::ChangeTRNWizard::Wizard::IneligibleForMergeError)
      end

      it "propagates the error" do
        expect { step.save! }
          .to raise_error(Admin::Teachers::ChangeTRNWizard::Wizard::IneligibleForMergeError)
      end
    end
  end

  describe "#next_step" do
    it "continues to confirmation" do
      expect(step.next_step).to eq(:confirmation)
    end
  end

  describe "#previous_step" do
    it "returns to TRN entry for a replacement" do
      expect(step.previous_step).to eq(:enter_trn)
    end

    context "when a merge is proposed" do
      let(:merge_proposed) { true }

      it "returns to the merge preview" do
        expect(step.previous_step).to eq(:merge_preview)
      end
    end
  end

  describe "#confirmation_message" do
    it "asks for confirmation of the replacement" do
      expect(step.confirmation_message).to eq("Confirm you want to change this teacher’s TRN")
    end

    context "when a merge is proposed" do
      let(:merge_proposed) { true }

      it "asks for confirmation of the merge" do
        expect(step.confirmation_message).to eq("Confirm you want to merge these teacher records")
      end

      it "uses the merge message when confirmation is not selected" do
        step.confirmed = "0"

        expect(step.save!).to be(false)
        expect(step.errors[:confirmed]).to contain_exactly("Confirm you want to merge these teacher records")
        expect(wizard).not_to have_received(:update!)
      end
    end
  end
end
