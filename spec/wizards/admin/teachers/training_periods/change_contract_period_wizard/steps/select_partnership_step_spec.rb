RSpec.describe Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::Steps::SelectPartnershipStep do
  subject(:step) { wizard.current_step }

  let(:wizard) do
    Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::Wizard.new(
      state_store:,
      current_step: :select_partnership,
      current_step_params: { select_partnership: { school_partnership_id: } }
    )
  end
  let(:state_store) do
    Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::StateStore.new(training_period:)
  end
  let(:training_period) { FactoryBot.build_stubbed(:training_period) }
  let(:available_school_partnership) { FactoryBot.create(:school_partnership) }
  let(:other_school_partnership) { FactoryBot.create(:school_partnership) }
  let(:school_partnership_id) { available_school_partnership.id }

  before do
    allow(state_store).to receive(:school_partnerships)
      .and_return(SchoolPartnership.where(id: available_school_partnership.id))
  end

  describe "validations" do
    context "when partnership is not present" do
      let(:school_partnership_id) { nil }

      it "is invalid with the correct error message" do
        expect(step).not_to be_valid
        expect(step.errors[:school_partnership_id]).to include("Select a partnership")
      end
    end

    context "when partnership is not available" do
      let(:school_partnership_id) { other_school_partnership.id }

      it "is invalid with the correct error message" do
        expect(step).not_to be_valid
        expect(step.errors[:school_partnership_id]).to include("Select a partnership")
      end
    end

    context "when partnership is available" do
      it { is_expected.to be_valid }
    end
  end

  describe "saving" do
    it "stores the selected partnership" do
      expect(wizard.save_current_step).to be(true)
      expect(state_store).to have_step_attribute(:school_partnership_id).with_value(available_school_partnership.id)
    end

    context "when invalid" do
      let(:school_partnership_id) { nil }

      it "does not store a partnership" do
        expect(wizard.save_current_step).to be(false)
        expect(state_store.school_partnership_id).to be_nil
      end
    end
  end
end
