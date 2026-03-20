RSpec.describe ContractPeriods::Historic do
  subject(:service) { described_class.new(teacher:) }

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:) }
  let(:contract_period_2021) { FactoryBot.create(:contract_period, year: 2021) }
  let(:contract_period_2022) { FactoryBot.create(:contract_period, year: 2022) }
  let(:contract_period_2024) { FactoryBot.create(:contract_period, year: 2024) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:) }

  describe "#training_started_in_closed_contract_period?" do
    context "when teacher is missing" do
      let(:teacher) { nil }

      it "returns false" do
        expect(service.training_started_in_closed_contract_period?).to be false
      end
    end

    context "when teacher has no ect_at_school_periods" do
      it "returns false" do
        expect(service.training_started_in_closed_contract_period?).to be false
      end
    end

    context "when training period is in a closed contract year (2021 or 2022)" do
      let(:contract_period) { contract_period_2021 }
      let!(:training_period) do
        FactoryBot.create(:training_period,
                          :provider_led,
                          :ongoing,
                          :with_active_lead_provider,
                          started_on: Date.new(2021, 7, 1),
                          ect_at_school_period:,
                          active_lead_provider:)
      end

      it "returns true" do
        expect(service.training_started_in_closed_contract_period?).to be true
      end
    end

    context "when training period is not in a closed contract year" do
      let(:contract_period) { contract_period_2024 }

      let!(:training_period) do
        FactoryBot.create(:training_period,
                          :provider_led,
                          :ongoing,
                          :with_active_lead_provider,
                          started_on: Date.new(2024, 7, 1),
                          ect_at_school_period:,
                          active_lead_provider:)
      end

      it "returns false" do
        expect(service.training_started_in_closed_contract_period?).to be false
      end
    end

    context "when teacher has multiple training periods" do
      let(:contract_period) { contract_period_2021 }
      let(:second_active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period: contract_period_2024) }
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:, started_on: Date.new(2021, 6, 1), finished_on: Date.new(2022, 6, 30)) }
      let(:second_ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:, started_on: Date.new(2024, 6, 1), finished_on: Date.new(2025, 6, 30)) }

      before do
        FactoryBot.create(:training_period,
                          :provider_led,
                          :ongoing,
                          :with_active_lead_provider,
                          started_on: Date.new(2021, 7, 1),
                          finished_on: Date.new(2022, 6, 30),
                          ect_at_school_period:,
                          active_lead_provider:)

        FactoryBot.create(:training_period,
                          :provider_led,
                          :ongoing,
                          :with_active_lead_provider,
                          started_on: Date.new(2024, 7, 1),
                          ect_at_school_period: second_ect_at_school_period,
                          active_lead_provider: second_active_lead_provider)
      end

      it "returns true if any are in closed years" do
        expect(service.training_started_in_closed_contract_period?).to be true
      end
    end
  end

  describe ".closed_contract_periods" do
    it "returns contract periods for 2021 and 2022" do
      contract_period_2021
      contract_period_2022

      closed_contract_periods = described_class.closed_contract_periods

      expect(closed_contract_periods.map(&:year)).to contain_exactly(2021, 2022)
    end
  end

  describe ".replacement_contract_period" do
    it "returns the contract period for 2024" do
      contract_period_2024

      replacement_contract_period = described_class.replacement_contract_period

      expect(replacement_contract_period.year).to eq(2024)
    end
  end
end
