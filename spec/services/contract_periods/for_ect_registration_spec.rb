describe ContractPeriods::ForECTRegistration do
  subject(:resolver) { described_class.new(started_on:, previous_training_period:) }

  let(:previous_training_period) { nil }
  let!(:contract_2024) do
    FactoryBot.create(
      :contract_period,
      year: 2024,
      started_on: Date.new(2024, 9, 1),
      finished_on: Date.new(2025, 8, 31)
    )
  end

  let!(:contract_2025) do
    FactoryBot.create(
      :contract_period,
      year: 2025,
      started_on: Date.new(2025, 9, 1),
      finished_on: Date.new(2026, 8, 31)
    )
  end

  describe "#call" do
    context "when started_on falls within a contract period" do
      let(:started_on) { Date.new(2024, 9, 5) }

      it "returns the contract period covering the start date" do
        expect(resolver.call).to eq(contract_2024)
      end
    end

    context "when started_on is exactly the start date of a contract period" do
      let(:started_on) { Date.new(2025, 9, 1) }

      it "returns the matching contract period" do
        expect(resolver.call).to eq(contract_2025)
      end
    end

    context "when started_on is the last included date of a contract period" do
      let(:started_on) { Date.new(2025, 8, 31) }

      it "returns the matching contract period" do
        expect(resolver.call).to eq(contract_2024)
      end
    end

    context "when started_on does not fall within any contract period" do
      let(:started_on) { Date.new(2023, 1, 1) }

      it "raises an error" do
        expect { resolver.call }.to raise_error(ContractPeriods::ForECTRegistration::NoContractPeriodFoundForStartedOnDate)
      end
    end

    context "when started_on is in a future period that does not yet exist" do
      let(:started_on) { Date.new(2026, 9, 1) }

      it "raises an error" do
        expect { resolver.call }.to raise_error(ContractPeriods::ForECTRegistration::NoContractPeriodFoundForStartedOnDate)
      end
    end

    context "when previous training period is provider-led in closed 2021" do
      let(:started_on) { Date.new(2025, 9, 1) }

      let!(:contract_2021) do
        FactoryBot.create(
          :contract_period,
          year: 2021,
          started_on: Date.new(2021, 9, 1),
          finished_on: Date.new(2022, 8, 31),
          enabled: false
        )
      end

      let(:previous_training_period) do
        instance_double(
          TrainingPeriod,
          provider_led_training_programme?: true,
          contract_period: contract_2021,
          expression_of_interest_contract_period: nil
        )
      end

      it "returns the 2024 contract period" do
        expect(resolver.call).to eq(contract_2024)
      end
    end

    context "when previous training period is provider-led in closed 2022" do
      let(:started_on) { Date.new(2025, 9, 1) }

      let!(:contract_2022) do
        FactoryBot.create(
          :contract_period,
          year: 2022,
          started_on: Date.new(2022, 9, 1),
          finished_on: Date.new(2023, 8, 31),
          enabled: false
        )
      end

      let(:previous_training_period) do
        instance_double(
          TrainingPeriod,
          provider_led_training_programme?: true,
          contract_period: contract_2022,
          expression_of_interest_contract_period: nil
        )
      end

      it "returns the 2024 contract period" do
        expect(resolver.call).to eq(contract_2024)
      end
    end

    context "when previous training period is not provider-led" do
      let(:started_on) { Date.new(2025, 9, 1) }

      let(:previous_training_period) do
        instance_double(
          TrainingPeriod,
          provider_led_training_programme?: false,
          contract_period: contract_2024,
          expression_of_interest_contract_period: nil
        )
      end

      it "returns the contract period for the start date" do
        expect(resolver.call).to eq(contract_2025)
      end
    end

    context "when previous training period is provider-led in an enabled contract period" do
      let(:started_on) { Date.new(2025, 9, 1) }

      let(:previous_training_period) do
        instance_double(
          TrainingPeriod,
          provider_led_training_programme?: true,
          contract_period: contract_2024,
          expression_of_interest_contract_period: nil
        )
      end

      it "returns the contract period for the start date" do
        expect(resolver.call).to eq(contract_2025)
      end
    end
  end
end
