RSpec.describe ContractPeriods::Reassigner do
  describe "#contract_period_closed?" do
    subject(:result) { described_class.new(training_period:).contract_period_closed? }

    context "when training period is provider-led in a payments-frozen contract period" do
      let(:contract_period) do
        instance_double(ContractPeriod, payments_frozen?: true)
      end

      let(:training_period) do
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

    context "when training period is provider-led but contract period is not payments frozen" do
      let(:contract_period) do
        instance_double(ContractPeriod, payments_frozen?: false)
      end

      let(:training_period) do
        instance_double(
          TrainingPeriod,
          provider_led_training_programme?: true,
          contract_period:,
          expression_of_interest_contract_period: nil
        )
      end

      it "returns false" do
        expect(result).to be false
      end
    end

    context "when training period uses expression_of_interest_contract_period" do
      let(:contract_period) do
        instance_double(ContractPeriod, payments_frozen?: true)
      end

      let(:training_period) do
        instance_double(
          TrainingPeriod,
          provider_led_training_programme?: true,
          contract_period: nil,
          expression_of_interest_contract_period: contract_period
        )
      end

      it "returns true" do
        expect(result).to be true
      end
    end

    context "when training period uses expression_of_interest_contract_period that is not payments frozen" do
      let(:contract_period) do
        instance_double(ContractPeriod, payments_frozen?: false)
      end

      let(:training_period) do
        instance_double(
          TrainingPeriod,
          provider_led_training_programme?: true,
          contract_period: nil,
          expression_of_interest_contract_period: contract_period
        )
      end

      it "returns false" do
        expect(result).to be false
      end
    end

    context "when training period is not provider-led" do
      let(:training_period) do
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

    context "when there is no training period" do
      let(:training_period) { nil }

      it "returns false" do
        expect(result).to be false
      end
    end
  end

  describe "successor_contract_period" do
    let!(:contract_period_2024) { FactoryBot.create(:contract_period, year: 2024) }

    it "returns the contract period for 2024" do
      successor_contract_period = described_class.new(training_period: nil).successor_contract_period

      expect(successor_contract_period.year).to eq(2024)
    end
  end
end
