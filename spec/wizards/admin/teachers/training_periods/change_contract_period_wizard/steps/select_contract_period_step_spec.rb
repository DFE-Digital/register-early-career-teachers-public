RSpec.describe Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::Steps::SelectContractPeriodStep do
  subject(:step) { wizard.current_step }

  let(:wizard) do
    Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::Wizard.new(
      state_store:,
      current_step: :select_contract_period,
      current_step_params: { select_contract_period: { contract_period_year: } }
    )
  end
  let(:state_store) do
    Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::StateStore.new(training_period:)
  end
  let(:training_period) { FactoryBot.build_stubbed(:training_period) }
  let(:available_contract_period) { FactoryBot.create(:contract_period, year: 2026) }
  let(:other_contract_period) { FactoryBot.create(:contract_period, year: 2027) }
  let(:contract_period_year) { available_contract_period.year }

  before do
    allow(state_store).to receive(:contract_periods)
      .and_return(ContractPeriod.where(year: available_contract_period.year))
  end

  describe "validations" do
    context "when contract period is not present" do
      let(:contract_period_year) { nil }

      it "is invalid with the correct error message" do
        expect(step).not_to be_valid
        expect(step.errors[:contract_period_year]).to include("Select a new contract period")
      end
    end

    context "when contract period is not available" do
      let(:contract_period_year) { other_contract_period.year }

      it "is invalid with the correct error message" do
        expect(step).not_to be_valid
        expect(step.errors[:contract_period_year]).to include("Select a new contract period")
      end
    end

    context "when contract period is available" do
      it { is_expected.to be_valid }
    end
  end

  describe "saving" do
    before { state_store.write(school_partnership_id: 123) }

    it "stores the selected contract period year and clears the selected partnership" do
      expect(wizard.save_current_step).to be(true)
      expect(state_store).to have_step_attribute(:contract_period_year).with_value(available_contract_period.year)
      expect(state_store.school_partnership_id).to be_nil
    end

    context "when invalid" do
      let(:contract_period_year) { nil }

      it "does not change the stored selections" do
        expect(wizard.save_current_step).to be(false)
        expect(state_store.contract_period_year).to be_nil
        expect(state_store.school_partnership_id).to eq(123)
      end
    end
  end
end
