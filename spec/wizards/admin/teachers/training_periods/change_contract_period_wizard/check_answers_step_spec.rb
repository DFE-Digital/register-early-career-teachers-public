RSpec.describe Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::CheckAnswersStep do
  subject(:step) { described_class.new(wizard:) }

  let(:wizard) do
    instance_double(
      Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::Wizard,
      store:
    )
  end
  let(:store) { FactoryBot.build(:session_repository) }

  describe "#previous_step" do
    it "returns select partnership" do
      expect(step.previous_step).to eq(:select_partnership)
    end
  end
end
