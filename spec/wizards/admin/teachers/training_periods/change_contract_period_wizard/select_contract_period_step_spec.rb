RSpec.describe Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::SelectContractPeriodStep do
  subject(:step) { described_class.new(wizard:, contract_period_year:) }

  let(:wizard) do
    instance_double(
      Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::Wizard,
      store:,
      contract_periods:
    )
  end
  let(:store) { FactoryBot.build(:session_repository) }
  let(:available_contract_period) { FactoryBot.create(:contract_period, year: 2026) }
  let(:other_contract_period) { FactoryBot.create(:contract_period, year: 2027) }
  let(:contract_periods) { ContractPeriod.where(year: available_contract_period.year) }
  let(:contract_period_year) { available_contract_period.year }

  before do
    allow(wizard).to receive(:valid_step?) { step.valid? }
    allow(wizard).to receive(:step_params)
      .and_return(ActionController::Parameters.new(contract_period_year:).permit(:contract_period_year))
  end

  describe "#save!" do
    before do
      store.school_partnership_id = "123"
    end

    it "stores the selected contract period year and clears the selected partnership" do
      expect { step.save! }
        .to change(store, :contract_period_year)
        .from(nil)
        .to(available_contract_period.year)

      expect(store.school_partnership_id).to be_nil
    end

    context "when invalid" do
      let(:contract_period_year) { nil }

      it "returns false without changing the stored selections" do
        result = step.save!

        expect(result).to be_falsey
        expect(store.contract_period_year).to be_nil
        expect(store.school_partnership_id).to eq("123")
      end
    end
  end

  describe "validations" do
    context "when contract period is not present" do
      let(:contract_period_year) { nil }

      it "is invalid with the correct error message" do
        expect(step).not_to be_valid
        expect(step.errors[:contract_period_year].map(&:squish)).to include("Select a new contract period")
      end
    end

    context "when contract period is not available" do
      let(:contract_period_year) { other_contract_period.year }

      it "is invalid with the correct error message" do
        expect(step).not_to be_valid
        expect(step.errors[:contract_period_year].map(&:squish)).to include("Select a new contract period")
      end
    end

    context "when contract period is available" do
      it { is_expected.to be_valid }
    end
  end
end
