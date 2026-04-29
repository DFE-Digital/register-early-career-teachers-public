RSpec.describe ContractPeriods::ForECTRegistration do
  subject(:resolver) do
    described_class.new(
      started_on:,
      previous_training_period:,
      reassignment:
    )
  end

  let(:previous_training_period) { nil }
  let(:reassignment) { nil }

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
    context "when started_on falls within an older contract period than current" do
      let(:started_on) { Date.new(2024, 9, 5) }

      it "returns the current contract period" do
        expect(resolver.call).to eq(contract_2025)
      end
    end

    context "when started_on is exactly the start date of the current contract period" do
      let(:started_on) { Date.new(2025, 9, 1) }

      it "returns the current contract period" do
        expect(resolver.call).to eq(contract_2025)
      end
    end

    context "when started_on is the last included date of an older contract period" do
      let(:started_on) { Date.new(2025, 8, 31) }

      it "returns the current contract period" do
        expect(resolver.call).to eq(contract_2025)
      end
    end

    context "when started_on does not fall within any contract period" do
      let(:started_on) { Date.new(2023, 1, 1) }

      it "returns the current contract period" do
        expect(resolver.call).to eq(contract_2025)
      end
    end

    context "when started_on is in a future period that does not yet exist" do
      let(:started_on) { Date.new(2026, 9, 1) }

      it "returns the current contract period" do
        expect(resolver.call).to eq(contract_2025)
      end
    end

    context "when there is a previous training period in an earlier contract period" do
      let(:started_on) { Date.new(2025, 9, 1) }

      let(:previous_training_period) do
        instance_double(
          TrainingPeriod,
          contract_period: contract_2024,
          provider_led_training_programme?: true
        )
      end

      let(:reassignment) do
        instance_double(
          ContractPeriods::Reassignment,
          required?: false
        )
      end

      it "returns the previous training period's contract period" do
        expect(resolver.call).to eq(contract_2024)
      end
    end

    context "when the training period should be reassigned" do
      let(:started_on) { Date.new(2025, 9, 1) }
      let(:previous_training_period) { instance_double(TrainingPeriod) }
      let(:reassignment) do
        instance_double(
          ContractPeriods::Reassignment,
          required?: true,
          successor_contract_period: contract_2024
        )
      end

      it "returns the successor contract period" do
        expect(resolver.call).to eq(contract_2024)
      end
    end

    context "when the training period should not be reassigned" do
      let(:started_on) { Date.new(2025, 9, 1) }

      let(:previous_training_period) do
        instance_double(
          TrainingPeriod,
          contract_period: contract_2024,
          provider_led_training_programme?: true
        )
      end

      let(:reassignment) do
        instance_double(
          ContractPeriods::Reassignment,
          required?: false
        )
      end

      it "returns the previous training period's contract period" do
        expect(resolver.call).to eq(contract_2024)
      end
    end
  end
end
