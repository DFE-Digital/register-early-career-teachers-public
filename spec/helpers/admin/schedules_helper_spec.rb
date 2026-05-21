RSpec.describe Admin::SchedulesHelper, type: :helper do
  describe "#schedule_name" do
    it "humanises the identifier" do
      expect(helper.schedule_name("ecf-standard-september")).to eq("Standard September")
      expect(helper.schedule_name("ecf-extended-january")).to eq("Extended January")
      expect(helper.schedule_name("ecf-replacement-april")).to eq("Replacement April")
    end
  end

  describe "#sort_schedules" do
    let(:contract_period) { FactoryBot.create(:contract_period) }

    before do
      FactoryBot.create(:schedule, identifier: "ecf-reduced-april", contract_period:)
      FactoryBot.create(:schedule, identifier: "ecf-standard-april", contract_period:)
      FactoryBot.create(:schedule, identifier: "ecf-standard-september", contract_period:)
      FactoryBot.create(:schedule, identifier: "ecf-reduced-january", contract_period:)
      FactoryBot.create(:schedule, identifier: "ecf-standard-january", contract_period:)
      FactoryBot.create(:schedule, identifier: "ecf-reduced-september", contract_period:)
    end

    it "orders a contract period's schedules" do
      expect(helper.sort_schedules(contract_period).map(&:identifier)).to eq(%w[
        ecf-standard-january
        ecf-standard-april
        ecf-standard-september
        ecf-reduced-january
        ecf-reduced-april
        ecf-reduced-september
      ])
    end
  end
end
