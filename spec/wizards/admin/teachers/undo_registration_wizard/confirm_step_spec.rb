RSpec.describe Admin::Teachers::UndoRegistrationWizard::ConfirmStep do
  subject(:step) do
    described_class.new(
      confirmed:,
      expected_action:,
      expected_training_period_ids:,
      expected_mentorship_period_ids:,
      wizard:
    )
  end

  let(:confirmed) { "1" }
  let(:expected_action) { "close" }
  let(:expected_training_period_ids) { "1" }
  let(:expected_mentorship_period_ids) { "2" }
  let(:undo_action) { "close" }
  let(:periods_will_be_closed) { true }
  let(:store) { FactoryBot.build(:session_repository) }
  let(:wizard) do
    instance_double(
      Admin::Teachers::UndoRegistrationWizard::Wizard,
      periods_will_be_closed?: periods_will_be_closed,
      undo_registration!: undo_action,
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
      expect(wizard).to receive(:undo_registration!).with(
        expected_action:,
        expected_training_period_ids: [1],
        expected_mentorship_period_ids: [2]
      )

      expect(step.save!).to be(true)
    end

    it "records the undo action and marks the registration as undone" do
      step.save!

      expect(store.undo_action).to eq(undo_action)
      expect(store.registration_undone).to be(true)
    end

    context "when the service reports that periods were deleted" do
      let(:expected_action) { "delete" }
      let(:undo_action) { "delete" }

      it "records delete as the undo action" do
        step.save!

        expect(store.undo_action).to eq("delete")
      end
    end

    context "when undoing the registration fails" do
      before do
        allow(wizard).to receive(:undo_registration!).and_raise("Unable to undo registration")
      end

      it "does not record that the registration has been undone" do
        expect { step.save! }.to raise_error(RuntimeError, "Unable to undo registration")

        expect(store.undo_action).to be_nil
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

    context "when the expected action is missing" do
      let(:expected_action) { nil }

      it "does not undo the registration" do
        expect(wizard).not_to receive(:undo_registration!)

        expect(step.save!).to be(false)
      end
    end

    context "when the reviewed period IDs are missing" do
      let(:expected_training_period_ids) { nil }

      it "does not undo the registration" do
        expect(wizard).not_to receive(:undo_registration!)

        expect(step.save!).to be(false)
      end
    end
  end
end
