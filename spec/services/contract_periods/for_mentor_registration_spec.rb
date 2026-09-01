RSpec.describe ContractPeriods::ForMentorRegistration do
  subject(:resolver) do
    described_class.new(
      started_on:,
      previous_training_period:
    )
  end

  let(:previous_training_period) { nil }

  let(:current_year) { current_contract_period.year }

  let!(:previous_contract_period) do
    FactoryBot.create(
      :contract_period,
      :previous
    )
  end

  let!(:current_contract_period) do
    FactoryBot.create(
      :contract_period,
      :current,
    )
  end

  describe "#call" do
    context "when there is no previous training period" do
      let(:started_on) { Date.new(current_year, 9, 1) }

      it "returns the registration contract period" do
        expect(resolver.call).to eq(current_contract_period)
      end
    end

    context "when there is a previous provider-led training period" do
      let(:started_on) { Date.new(current_year, 9, 1) }

      let(:previous_training_period) do
        instance_double(
          TrainingPeriod,
          contract_period: previous_contract_period,
          expression_of_interest: nil,
          provider_led_training_programme?: true
        )
      end

      it "returns the previous training period's contract period" do
        expect(resolver.call).to eq(previous_contract_period)
      end
    end

    context "when the mentor was previously registered in the 2023 contract period" do
      let(:started_on) { Date.new(current_year, 9, 1) }
      let(:contract_2023) { FactoryBot.create(:contract_period, year: 2023) }

      let(:previous_training_period) do
        instance_double(
          TrainingPeriod,
          contract_period: contract_2023,
          expression_of_interest: nil,
          provider_led_training_programme?: true
        )
      end

      it "preserves the 2023 contract period" do
        expect(resolver.call).to eq(contract_2023)
      end
    end

    context "when the mentor was previously registered in a payments frozen contract period (2022)" do
      let(:started_on) { Date.new(current_year, 9, 1) }
      let(:frozen_contract) { FactoryBot.create(:contract_period, :with_payments_frozen, year: 2022) }

      let(:previous_training_period) do
        instance_double(
          TrainingPeriod,
          contract_period: frozen_contract,
          expression_of_interest: nil,
          provider_led_training_programme?: true
        )
      end

      it "falls back to the registration contract period" do
        expect(resolver.call).to eq(current_contract_period)
      end
    end

    context "when there is a previous school-led training period" do
      let(:started_on) { Date.new(current_year, 9, 1) }

      let(:previous_training_period) do
        instance_double(
          TrainingPeriod,
          contract_period: previous_contract_period,
          provider_led_training_programme?: false
        )
      end

      it "returns the registration contract period" do
        expect(resolver.call).to eq(current_contract_period)
      end
    end

    context "when the previous provider-led training period used an EOI" do
      let(:started_on) { Date.new(current_year, 9, 1) }

      let(:framework_agreement) do
        instance_double(FrameworkAgreement, contract_period: previous_contract_period)
      end

      let(:previous_training_period) do
        instance_double(
          TrainingPeriod,
          contract_period: nil,
          expression_of_interest: framework_agreement,
          provider_led_training_programme?: true
        )
      end

      it "returns the expression of interest contract period" do
        expect(resolver.call).to eq(previous_contract_period)
      end
    end

    context "when the previous contract period is payments frozen" do
      let(:started_on) { Date.new(current_year, 9, 1) }

      let(:previous_training_period) do
        instance_double(
          TrainingPeriod,
          contract_period: previous_contract_period,
          expression_of_interest: nil,
          provider_led_training_programme?: true
        )
      end

      before { allow(previous_contract_period).to receive(:payments_frozen?).and_return(true) }

      it "returns the registration contract period" do
        expect(resolver.call).to eq(current_contract_period)
      end
    end
  end
end
