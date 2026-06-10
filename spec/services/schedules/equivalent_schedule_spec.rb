RSpec.describe Schedules::EquivalentSchedule do
  subject(:equivalent_schedule) do
    described_class.new(
      source_schedule:,
      target_contract_period:
    ).schedule
  end

  let(:source_contract_period) { FactoryBot.create(:contract_period, year: 2025) }
  let(:target_contract_period) { FactoryBot.create(:contract_period, year: 2026) }
  let(:source_schedule) do
    FactoryBot.create(
      :schedule,
      contract_period: source_contract_period,
      identifier: "ecf-standard-april"
    )
  end

  context "when a schedule with the same identifier exists in the target contract period" do
    let!(:target_schedule) do
      FactoryBot.create(
        :schedule,
        contract_period: target_contract_period,
        identifier: source_schedule.identifier
      )
    end

    it "returns the matching schedule" do
      expect(equivalent_schedule).to eq(target_schedule)
    end
  end

  context "when no schedule with the same identifier exists in the target contract period" do
    before do
      FactoryBot.create(
        :schedule,
        contract_period: target_contract_period,
        identifier: "ecf-standard-september"
      )
    end

    it "returns nil" do
      expect(equivalent_schedule).to be_nil
    end
  end
end
