RSpec.describe Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::CheckAnswersStep do
  subject(:step) { described_class.new(wizard:) }

  let(:wizard) do
    instance_double(
      Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::Wizard,
      store:,
      partnership_selection_required?: partnership_selection_required
    )
  end
  let(:store) { FactoryBot.build(:session_repository) }
  let(:partnership_selection_required) { true }

  describe "#previous_step" do
    it "returns select partnership" do
      expect(step.previous_step).to eq(:select_partnership)
    end

    context "when the partnership selection is skipped" do
      let(:partnership_selection_required) { false }

      it "returns select contract period" do
        expect(step.previous_step).to eq(:select_contract_period)
      end
    end
  end
end
