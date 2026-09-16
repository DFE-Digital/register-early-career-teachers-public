RSpec.describe Admin::Teachers::UndoRegistrationWizard::ConfirmStep do
  subject(:step) { described_class.new(confirmed:, wizard:) }

  let(:confirmed) { "1" }
  let(:store) { FactoryBot.build(:session_repository) }
  let(:author) { instance_double(User) }
  let(:at_school_period) { instance_double(ECTAtSchoolPeriod) }
  let(:wizard) do
    instance_double(
      Admin::Teachers::UndoRegistrationWizard::Wizard,
      author:,
      at_school_period:,
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
    let(:undo_registration) { instance_double(::Teachers::UndoRegistration, undo!: true) }

    before do
      allow(::Teachers::UndoRegistration).to receive(:new).with(
        author:,
        at_school_period:,
        reason: :registered_in_error
      ).and_return(undo_registration)
    end

    it "undoes the registration" do
      expect(undo_registration).to receive(:undo!)

      expect(step.save!).to be(true)
    end

    it "records that the registration has been undone" do
      step.save!

      expect(store.registration_undone).to be(true)
    end

    context "when undoing the registration fails" do
      before do
        allow(undo_registration).to receive(:undo!).and_raise("Unable to undo registration")
      end

      it "does not record that the registration has been undone" do
        expect { step.save! }.to raise_error(RuntimeError, "Unable to undo registration")

        expect(store.registration_undone).to be_nil
      end
    end

    context "when the confirmation is not selected" do
      let(:confirmed) { "0" }

      it "does not undo the registration" do
        expect(::Teachers::UndoRegistration).not_to receive(:new)

        expect(step.save!).to be(false)
      end

      it "adds a validation error" do
        step.save!

        expect(step.errors[:confirmed]).to contain_exactly("Confirm you want to undo this registration and close this school period")
      end

      it "does not record that the registration has been undone" do
        step.save!

        expect(store.registration_undone).to be_nil
      end
    end
  end
end
