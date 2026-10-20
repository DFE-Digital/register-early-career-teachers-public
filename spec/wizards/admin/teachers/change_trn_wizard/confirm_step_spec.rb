RSpec.describe Admin::Teachers::ChangeTRNWizard::ConfirmStep do
  subject(:step) do
    described_class.new(confirmed:, expected_trn:, wizard:)
  end

  let(:expected_trn) { "2345678" }
  let(:confirmed) { "1" }
  let(:store) { FactoryBot.build(:session_repository) }
  let(:wizard) do
    instance_double(
      Admin::Teachers::ChangeTRNWizard::Wizard,
      store:,
      replace_trn!: true
    )
  end

  before do
    store.trn = "2345678"
  end

  describe "#save!" do
    it "replaces the TRN and marks the journey as complete" do
      expect(wizard).to receive(:replace_trn!)

      expect(step.save!).to be(true)
      expect(store.trn_replaced).to be(true)
    end

    context "when confirmation is not selected" do
      let(:confirmed) { "0" }

      it "does not replace the TRN" do
        expect(wizard).not_to receive(:replace_trn!)

        expect(step.save!).to be(false)
        expect(step.errors[:confirmed]).to contain_exactly(
          "Confirm you want to change this teacher’s TRN"
        )
        expect(store.trn_replaced).to be_nil
      end
    end

    context "when confirmation is missing" do
      let(:confirmed) { nil }

      it "does not replace the TRN" do
        expect(wizard).not_to receive(:replace_trn!)

        expect(step.save!).to be(false)
        expect(store.trn_replaced).to be_nil
      end
    end

    context "when replacement fails" do
      before do
        allow(wizard).to receive(:replace_trn!)
          .and_raise(::Teachers::ReplaceTRN::TeacherNotDeactivated)
      end

      it "does not mark the journey as complete" do
        expect { step.save! }
          .to raise_error(::Teachers::ReplaceTRN::TeacherNotDeactivated)

        expect(store.trn_replaced).to be_nil
      end
    end

    context "when the proposed TRN has changed" do
      let(:expected_trn) { "3456789" }

      it "rejects confirmation without replacing the TRN" do
        expect(wizard).not_to receive(:replace_trn!)

        expect { step.save! }
          .to raise_error(described_class::ProposedTRNChanged)

        expect(store.trn_replaced).to be_nil
      end
    end

    context "when the reviewed TRN is missing" do
      let(:expected_trn) { nil }

      it "rejects confirmation without replacing the TRN" do
        expect(wizard).not_to receive(:replace_trn!)

        expect { step.save! }
          .to raise_error(described_class::ProposedTRNChanged)

        expect(store.trn_replaced).to be_nil
      end
    end
  end
end
