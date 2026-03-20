RSpec.describe ContractPeriods::MoveFromClosedProviderLedPeriod do
  subject(:result) { described_class.new(previous_training_period:).call }

  context "when previous training period is provider-led in closed 2021" do
    let(:contract_period) do
      FactoryBot.create(
        :contract_period,
        year: 2021,
        enabled: false
      )
    end

    let(:previous_training_period) do
      instance_double(
        TrainingPeriod,
        provider_led_training_programme?: true,
        contract_period:,
        expression_of_interest_contract_period: nil
      )
    end

    it "returns true" do
      expect(result).to be true
    end
  end

  context "when previous training period is not provider-led" do
    let(:previous_training_period) do
      instance_double(
        TrainingPeriod,
        provider_led_training_programme?: false,
        contract_period: nil,
        expression_of_interest_contract_period: nil
      )
    end

    it "returns false" do
      expect(result).to be false
    end
  end
end
