RSpec.describe ContractPeriods::ForMentorRegistration do
  subject(:resolver) do
    described_class.new(
      started_on:,
      previous_training_period:
    )
  end

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
    context "when there is no previous training period" do
      let(:started_on) { Date.new(2025, 9, 1) }

      it "returns the registration contract period" do
        expect(resolver.call).to eq(contract_2025)
      end
    end

    context "when there is a previous provider-led training period" do
      let(:started_on) { Date.new(2025, 9, 1) }

      let(:previous_training_period) do
        instance_double(
          TrainingPeriod,
          contract_period: contract_2024,
          expression_of_interest: nil,
          school_partnership: nil,
          schedule: nil,
          provider_led_training_programme?: true
        )
      end

      it "returns the previous training period's contract period" do
        expect(resolver.call).to eq(contract_2024)
      end
    end

    context "when the mentor was previously registered in the 2023 contract period" do
      let(:started_on) { Date.new(2025, 9, 1) }
      let(:contract_2023) { FactoryBot.create(:contract_period, year: 2023) }

      let(:previous_training_period) do
        instance_double(
          TrainingPeriod,
          contract_period: contract_2023,
          expression_of_interest: nil,
          school_partnership: nil,
          schedule: nil,
          provider_led_training_programme?: true
        )
      end

      it "preserves the 2023 contract period" do
        expect(resolver.call).to eq(contract_2023)
      end
    end

    context "when the mentor was previously registered in a payments frozen contract period (2022)" do
      let(:started_on) { Date.new(2025, 9, 1) }
      let(:frozen_contract) { FactoryBot.create(:contract_period, :with_payments_frozen, year: 2022) }

      let(:previous_training_period) do
        instance_double(
          TrainingPeriod,
          contract_period: frozen_contract,
          expression_of_interest: nil,
          school_partnership: nil,
          schedule: nil,
          provider_led_training_programme?: true
        )
      end

      it "falls back to the registration contract period if the previous period is frozen" do
        expect(resolver.call).to eq(contract_2025)
      end
    end

    context "when there is a previous school-led training period" do
      let(:started_on) { Date.new(2025, 9, 1) }

      let(:previous_training_period) do
        instance_double(
          TrainingPeriod,
          contract_period: contract_2024,
          provider_led_training_programme?: false
        )
      end

      it "returns the registration contract period" do
        expect(resolver.call).to eq(contract_2025)
      end
    end

    context "when the previous provider-led training period used an EOI" do
      let(:started_on) { Date.new(2025, 9, 1) }

      let(:active_lead_provider) do
        instance_double(ActiveLeadProvider, contract_period: contract_2024)
      end

      let(:previous_training_period) do
        instance_double(
          TrainingPeriod,
          contract_period: nil,
          expression_of_interest: active_lead_provider,
          school_partnership: nil,
          schedule: nil,
          provider_led_training_programme?: true
        )
      end

      it "returns the expression of interest contract period" do
        expect(resolver.call).to eq(contract_2024)
      end
    end

    context "when the previous provider-led training period used a school partnership" do
      let(:started_on) { Date.new(2025, 9, 1) }

      let(:active_lead_provider) do
        instance_double(ActiveLeadProvider, contract_period: contract_2024)
      end

      let(:school_partnership) do
        instance_double(SchoolPartnership, active_lead_provider:)
      end

      let(:previous_training_period) do
        instance_double(
          TrainingPeriod,
          contract_period: nil,
          expression_of_interest: nil,
          school_partnership:,
          schedule: nil,
          provider_led_training_programme?: true
        )
      end

      it "returns the school partnership contract period" do
        expect(resolver.call).to eq(contract_2024)
      end
    end

    context "when the previous provider-led training period when the contract period can only be derived from the schedule" do
      let(:started_on) { Date.new(2025, 9, 1) }

      let(:schedule) do
        instance_double(Schedule, contract_period: contract_2024)
      end

      let(:previous_training_period) do
        instance_double(
          TrainingPeriod,
          contract_period: nil,
          expression_of_interest: nil,
          school_partnership: nil,
          schedule:,
          provider_led_training_programme?: true
        )
      end

      it "returns the schedule contract period" do
        expect(resolver.call).to eq(contract_2024)
      end
    end

    context "when the previous contract period is payments frozen" do
      let(:started_on) { Date.new(2025, 9, 1) }

      let(:previous_training_period) do
        instance_double(
          TrainingPeriod,
          contract_period: contract_2024,
          expression_of_interest: nil,
          school_partnership: nil,
          schedule: nil,
          provider_led_training_programme?: true
        )
      end

      before { allow(contract_2024).to receive(:payments_frozen?).and_return(true) }

      it "returns the registration contract period" do
        expect(resolver.call).to eq(contract_2025)
      end
    end
  end
end
