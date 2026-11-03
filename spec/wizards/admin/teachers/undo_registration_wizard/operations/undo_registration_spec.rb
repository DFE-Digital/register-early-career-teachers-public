RSpec.describe Admin::Teachers::UndoRegistrationWizard::Operations::UndoRegistration do
  subject(:operation) { described_class.new(repository: state_store.repository, step:) }

  let(:wizard) do
    Admin::Teachers::UndoRegistrationWizard::Wizard.new(
      state_store:,
      current_step: :confirm,
      current_step_params: ActionController::Parameters.new(
        confirm: {
          confirmed: "1",
          expected_action:,
          expected_training_period_ids:,
          expected_mentorship_period_ids:,
          expected_at_school_period_gid:
        }
      )
    )
  end
  let(:state_store) do
    Admin::Teachers::UndoRegistrationWizard::StateStore.new(teacher:, author: instance_double(User))
  end
  let(:teacher) { FactoryBot.build_stubbed(:teacher) }
  let(:step) { wizard.current_step }
  let(:expected_action) { "close" }
  let(:expected_training_period_ids) { ["", "1", "2"] }
  let(:expected_mentorship_period_ids) { ["", "3", "4"] }
  let(:expected_at_school_period_gid) { "gid://app/ECTAtSchoolPeriod/5" }
  let(:undo_action) { "close" }

  before do
    allow(state_store).to receive(:undo_registration!).and_return(undo_action)
  end

  describe "#execute" do
    it "removes blank period IDs, converts them to integers, and undoes the registration" do
      expect(state_store).to receive(:undo_registration!).with(
        expected_action:,
        expected_training_period_ids: [1, 2],
        expected_mentorship_period_ids: [3, 4],
        expected_at_school_period_gid:
      )

      expect(operation.execute).to eq(success: true)
    end

    it "stores only the undo action and completion flag" do
      operation.execute

      expect(state_store.read).to eq(undo_action: "close", registration_undone: true)
    end

    context "when the reviewed details have changed" do
      before do
        allow(state_store).to receive(:undo_registration!).and_raise(::Teachers::UndoRegistration::ConfirmationMismatchError)
      end

      it "does not mark the registration as undone" do
        expect { operation.execute }.to raise_error(::Teachers::UndoRegistration::ConfirmationMismatchError)
        expect(state_store.read).to be_empty
      end
    end

    context "when the service reports that periods were deleted" do
      let(:expected_action) { "delete" }
      let(:undo_action) { "delete" }

      it "records delete as the undo action" do
        operation.execute

        expect(state_store.undo_action).to eq("delete")
      end
    end

    context "when the reviewed associated period collections are empty" do
      let(:expected_training_period_ids) { [""] }
      let(:expected_mentorship_period_ids) { [""] }

      it "passes empty collections to the service" do
        expect(state_store).to receive(:undo_registration!).with(
          expected_action:,
          expected_training_period_ids: [],
          expected_mentorship_period_ids: [],
          expected_at_school_period_gid:
        )

        expect(operation.execute).to eq(success: true)
      end
    end

    context "when undoing the registration fails" do
      before do
        allow(state_store).to receive(:undo_registration!).and_raise("Unable to undo registration")
      end

      it "does not record that the registration has been undone" do
        expect { operation.execute }.to raise_error(RuntimeError, "Unable to undo registration")

        expect(state_store.read).to be_empty
      end
    end
  end
end
