RSpec.describe Admin::Teachers::UndoRegistrationWizard::ConfirmStep do
  subject(:step) { described_class.new(confirmed:, expected_action:, wizard:) }

  let(:confirmed) { "1" }
  let(:expected_action) { "close" }
  let(:periods_will_be_closed) { true }
  let(:store) { FactoryBot.build(:session_repository) }
  let(:wizard) do
    instance_double(
      Admin::Teachers::UndoRegistrationWizard::Wizard,
      periods_will_be_closed?: periods_will_be_closed,
      undo_registration!: true,
      store:
    )
  end

  describe "#previous_step" do
    it "returns the start step" do
      expect(step.previous_step).to eq(:start)
    end
  end

  describe "#next_step" do
    it "returns the confirmation step" do
      expect(step.next_step).to eq(:confirmation)
    end
  end

  describe "#save!" do
    it "undoes the registration" do
      expect(wizard).to receive(:undo_registration!).with(expected_action:)

      expect(step.save!).to be(true)
    end

    it "records that the registration has been undone" do
      step.save!

      expect(store.registration_undone).to be(true)
    end

    context "when undoing the registration fails" do
      before do
        allow(wizard).to receive(:undo_registration!).and_raise("Unable to undo registration")
      end

      it "does not record that the registration has been undone" do
        expect { step.save! }.to raise_error(RuntimeError, "Unable to undo registration")

        expect(store.registration_undone).to be_nil
      end
    end

    context "when the confirmation is not selected" do
      let(:confirmed) { "0" }

      it "does not undo the registration" do
        expect(wizard).not_to receive(:undo_registration!)

        expect(step.save!).to be(false)
      end

      context "when the periods would be closed" do
        it "adds a validation error" do
          step.save!

          expect(step.errors[:confirmed]).to contain_exactly("Confirm you want to undo this registration and close this school period")
        end
      end

      context "when the periods would be deleted" do
        let(:periods_will_be_closed) { false }

        it "adds a validation error" do
          step.save!

          expect(step.errors[:confirmed]).to contain_exactly("Confirm you want to undo this registration and delete this school period")
        end
      end

      it "does not record that the registration has been undone" do
        step.save!

        expect(store.registration_undone).to be_nil
      end
    end
  end
end
