RSpec.describe Admin::Statements::FilterComponent, type: :component do
  let(:filter_params) { {} }
  let(:component) { described_class.new filter_params: }

  context ".lead_providers" do
    let!(:lead_provider1) { create(:lead_provider, name: "C") }
    let!(:lead_provider2) { create(:lead_provider, name: "A") }
    let!(:lead_provider3) { create(:lead_provider, name: "B") }

    it "returns lead providers in alphabetical order" do
      expect(component.lead_providers).to contain_exactly(lead_provider2, lead_provider3, lead_provider1)
    end
  end

  context ".lead_provider_id" do
    let(:filter_params) { { lead_provider_id: 123 } }

    it "returns filter param lead_provider_id" do
      expect(component.lead_provider_id).to eq(123)
    end
  end

  context ".contract_periods" do
    let!(:contract_period1) { create(:contract_period, year: 2025) }
    let!(:contract_period2) { create(:contract_period, year: 2021) }
    let!(:contract_period3) { create(:contract_period, year: 2022) }

    it "returns contract_period in year order" do
      expect(component.contract_periods).to contain_exactly(contract_period2, contract_period3, contract_period1)
    end
  end

  context ".contract_period_id" do
    let(:filter_params) { { contract_period_id: 2025 } }

    it "returns filter param contract_period_id" do
      expect(component.contract_period_id).to eq(2025)
    end
  end

  context ".statement_dates" do
    let!(:statement1) { create(:statement, year: 2025, month: 5) }
    let!(:statement2) { create(:statement, year: 2024, month: 5) }
    let!(:statement3) { create(:statement, year: 2023, month: 5) }

    it "returns statement dates in ascending order" do
      dates = component.statement_dates
      expect(dates[0].id).to eq("2023-5")
      expect(dates[0].name).to eq("May 2023")

      expect(dates[1].id).to eq("2024-5")
      expect(dates[1].name).to eq("May 2024")

      expect(dates[2].id).to eq("2025-5")
      expect(dates[2].name).to eq("May 2025")
    end
  end

  context ".statement_date" do
    let(:filter_params) { { statement_date: "2025-01" } }

    it "returns filter param statement_date" do
      expect(component.statement_date).to eq("2025-01")
    end
  end

  context ".statement_types" do
    it "returns statement types" do
      dates = component.statement_types
      expect(dates[0].id).to eq("all")
      expect(dates[0].name).to eq("All")

      expect(dates[1].id).to eq("output_fee")
      expect(dates[1].name).to eq("Output statements")

      expect(dates[2].id).to eq("service_fee")
      expect(dates[2].name).to eq("Service fee statements")
    end
  end

  context ".statement_type" do
    let(:filter_params) { { statement_type: "all" } }

    it "returns filter param statement_type" do
      expect(component.statement_type).to eq("all")
    end
  end
end
