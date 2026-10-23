RSpec.describe Admin::Teachers::ChangeTRNWizard::ConfirmMergeStep do
  subject(:step) do
    described_class.new(confirmed:, expected_trn:, wizard:)
  end

  let(:confirmed) { "1" }
  let(:expected_trn) { "2345678" }
  let(:store) { FactoryBot.build(:session_repository) }
  let(:wizard) do
    instance_double(
      Admin::Teachers::ChangeTRNWizard::Wizard,
      store:,
      merge_trn!: true
    )
  end

  before do
    store.trn = "2345678"
  end

  describe "#save!" do
    it "merges the records and marks the journey as complete" do
      expect(wizard).to receive(:merge_trn!)

      expect(step.save!).to be(true)
      expect(store.records_merged).to be(true)
    end

    context "when confirmation is not selected" do
      let(:confirmed) { "0" }

      it "does not merge the records" do
        expect(wizard).not_to receive(:merge_trn!)

        expect(step.save!).to be(false)
        expect(step.errors[:confirmed]).to contain_exactly(
          "Confirm you want to merge these teacher records"
        )
        expect(store.records_merged).to be_nil
      end
    end

    context "when confirmation is missing" do
      let(:confirmed) { nil }

      it "does not merge the records" do
        expect(wizard).not_to receive(:merge_trn!)

        expect(step.save!).to be(false)
        expect(step.errors[:confirmed]).to contain_exactly(
          "Confirm you want to merge these teacher records"
        )
        expect(store.records_merged).to be_nil
      end
    end

    context "when the proposed TRN has changed" do
      let(:expected_trn) { "3456789" }

      it "rejects confirmation without merging the records" do
        expect(wizard).not_to receive(:merge_trn!)

        expect { step.save! }
          .to raise_error(described_class::ProposedTRNChangedError)

        expect(store.records_merged).to be_nil
      end
    end

    context "when the reviewed TRN is missing" do
      let(:expected_trn) { nil }

      it "rejects confirmation without merging the records" do
        expect(wizard).not_to receive(:merge_trn!)

        expect { step.save! }
          .to raise_error(described_class::ProposedTRNChangedError)

        expect(store.records_merged).to be_nil
      end
    end

    context "when the merge fails" do
      before do
        allow(wizard).to receive(:merge_trn!)
          .and_raise(Admin::Teachers::ChangeTRNWizard::Wizard::IneligibleForMergeError)
      end

      it "does not mark the journey as complete" do
        expect { step.save! }
          .to raise_error(Admin::Teachers::ChangeTRNWizard::Wizard::IneligibleForMergeError)

        expect(store.records_merged).to be_nil
      end
    end
  end

  describe "#previous_step" do
    it "returns to the merge preview" do
      expect(step.previous_step).to eq(:merge_preview)
    end
  end

  describe "#next_step" do
    it "continues to the merge success page" do
      expect(step.next_step).to eq(:records_merged)
    end
  end
end
