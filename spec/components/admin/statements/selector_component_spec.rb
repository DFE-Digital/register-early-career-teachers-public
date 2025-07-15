RSpec.describe Admin::Statements::SelectorComponent, type: :component do
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period: statement_contract_period) }
  let(:statement) { FactoryBot.create(:statement, active_lead_provider:) }
  let(:component) { described_class.new statement: }
  let(:statement_lead_provider) { statement.active_lead_provider.lead_provider }
  let(:statement_contract_period) { FactoryBot.create(:contract_period, year: 2034) }

  context ".lead_providers" do
    let!(:lead_provider1) { FactoryBot.create(:lead_provider, name: "AAAC") }
    let!(:lead_provider2) { FactoryBot.create(:lead_provider, name: "AAAA") }
    let!(:lead_provider3) { FactoryBot.create(:lead_provider, name: "AAAB") }

    it "returns lead providers in alphabetical order" do
      expect(component.lead_providers).to contain_exactly(lead_provider2, lead_provider3, lead_provider1, statement_lead_provider)
    end
  end

  context ".lead_provider_id" do
    it "returns lead_provider_id from statement" do
      expect(component.lead_provider_id).to eq(statement.active_lead_provider.lead_provider_id)
    end
  end

  context ".contract_periods" do
    let!(:contract_period1) { FactoryBot.create(:contract_period, year: 2035) }
    let!(:contract_period2) { FactoryBot.create(:contract_period, year: 2031) }
    let!(:contract_period3) { FactoryBot.create(:contract_period, year: 2032) }

    it "returns contract_period in year order" do
      expect(component.contract_periods.map(&:year)).to contain_exactly(
        statement_contract_period.year,
        contract_period2.year,
        contract_period3.year,
        contract_period1.year
      )
    end
  end

  context ".contract_period_id" do
    it "returns contract_period_id from statement" do
      expect(component.contract_period_id).to eq(statement.active_lead_provider.contract_period_id)
    end
  end

  context ".statement_dates" do
    let!(:statement1) { FactoryBot.create(:statement, year: 2021, month: 3) }
    let!(:statement2) { FactoryBot.create(:statement, year: 2021, month: 2) }
    let!(:statement3) { FactoryBot.create(:statement, year: 2021, month: 1) }

    it "returns statement dates in ascending order" do
      dates = component.statement_dates
      expect(dates[0].id).to eq("2021-1")
      expect(dates[0].name).to eq("January 2021")

      expect(dates[1].id).to eq("2021-2")
      expect(dates[1].name).to eq("February 2021")

      expect(dates[2].id).to eq("2021-3")
      expect(dates[2].name).to eq("March 2021")
    end
  end

  context ".statement_date" do
    it "returns statement_date from statement" do
      expect(component.statement_date).to eq([statement.year, statement.month].join("-"))
    end
  end
end
