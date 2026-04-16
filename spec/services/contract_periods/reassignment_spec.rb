RSpec.describe ContractPeriods::Reassignment do
  let(:training_period) do
    instance_double(
      TrainingPeriod,
      provider_led_training_programme?: provider_led_training_programme,
      for_mentor?: for_mentor,
      contract_period:,
      expression_of_interest_contract_period:
    )
  end

  let(:contract_period) { nil }
  let(:expression_of_interest_contract_period) { nil }
  let(:provider_led_training_programme) { true }
  let(:for_mentor) { false }

  describe "#required?" do
    subject { described_class.new(training_period:).required? }

    context "when the training period is provider-led in a payments-frozen contract period" do
      let(:contract_period) do
        instance_double(ContractPeriod, payments_frozen?: true)
      end

      it { is_expected.to be_truthy }
    end

    context "when the training period is provider-led but contract period is not payments frozen" do
      let(:contract_period) do
        instance_double(ContractPeriod, payments_frozen?: false)
      end

      it { is_expected.to be_falsey }
    end

    context "when the training period uses expression_of_interest_contract_period" do
      let(:expression_of_interest_contract_period) do
        instance_double(ContractPeriod, payments_frozen?: true)
      end

      it { is_expected.to be_truthy }
    end

    context "when the training period uses expression_of_interest_contract_period that is not payments frozen" do
      let(:expression_of_interest_contract_period) do
        instance_double(ContractPeriod, payments_frozen?: false)
      end

      it { is_expected.to be_falsey }
    end

    context "when the training period is not provider-led" do
      let(:provider_led_training_programme) { false }

      it { is_expected.to be_falsey }
    end

    context "when the training period is for a mentor" do
      let(:for_mentor) { true }

      it { is_expected.to be_falsey }
    end

    context "when there is no training period" do
      let(:training_period) { nil }

      it { is_expected.to be_falsey }
    end
  end

  describe "successor_contract_period" do
    let!(:contract_period_2024) { FactoryBot.create(:contract_period, year: 2024) }

    it "returns the contract period for 2024" do
      successor_contract_period = described_class.new(training_period: nil).successor_contract_period

      expect(successor_contract_period.year).to eq(2024)
    end
  end

  describe "assigned_contract_period" do
    subject { described_class.new(training_period:).assigned_contract_period }

    context "when training period has a contract period" do
      let(:contract_period) { instance_double(ContractPeriod) }

      it { is_expected.to eq(contract_period) }
    end

    context "when training period does not have a contract period but has an expression of interest contract period" do
      let(:expression_of_interest_contract_period) { instance_double(ContractPeriod) }

      it { is_expected.to eq(expression_of_interest_contract_period) }
    end

    context "when training period does not have a contract period or an expression of interest contract period" do
      it { is_expected.to be_nil }
    end

    context "when a training period has both a contract period and an expression of interest contract period" do
      let(:contract_period) { instance_double(ContractPeriod) }
      let(:expression_of_interest_contract_period) { instance_double(ContractPeriod) }

      it { is_expected.to eq(contract_period) }
    end

    context "when there is no training period" do
      let(:training_period) { nil }

      it { is_expected.to be_nil }
    end
  end
end
