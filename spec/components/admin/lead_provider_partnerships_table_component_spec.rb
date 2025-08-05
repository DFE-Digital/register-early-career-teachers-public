RSpec.describe Admin::LeadProviderPartnershipsTableComponent, type: :component do
  let(:delivery_partner) { FactoryBot.create(:delivery_partner, name: "Test Delivery Partner") }
  let(:contract_period_2024) { FactoryBot.create(:contract_period, year: 2024) }
  let(:contract_period_2025) { FactoryBot.create(:contract_period, year: 2025) }

  let(:lead_provider_1) { FactoryBot.create(:lead_provider, name: "Lead Provider One") }
  let(:lead_provider_2) { FactoryBot.create(:lead_provider, name: "Lead Provider Two") }
  let(:lead_provider_3) { FactoryBot.create(:lead_provider, name: "Lead Provider Three") }

  let(:active_lead_provider_1) { FactoryBot.create(:active_lead_provider, lead_provider: lead_provider_1, contract_period: contract_period_2024) }
  let(:active_lead_provider_2) { FactoryBot.create(:active_lead_provider, lead_provider: lead_provider_2, contract_period: contract_period_2024) }
  let(:active_lead_provider_3) { FactoryBot.create(:active_lead_provider, lead_provider: lead_provider_3, contract_period: contract_period_2025) }

  let(:partnerships) do
    [
      FactoryBot.create(:lead_provider_delivery_partnership, delivery_partner:, active_lead_provider: active_lead_provider_1),
      FactoryBot.create(:lead_provider_delivery_partnership, delivery_partner:, active_lead_provider: active_lead_provider_2),
      FactoryBot.create(:lead_provider_delivery_partnership, delivery_partner:, active_lead_provider: active_lead_provider_3)
    ]
  end

  let(:component) do
    described_class.new(
      lead_provider_partnerships: partnerships,
      delivery_partner:,
      page: "2",
      q: "search"
    )
  end

  describe "rendering" do
    context "when there are partnerships" do
      before { render_inline(component) }

      it "renders the table with correct caption" do
        expect(page).to have_css("table")
        expect(page).to have_content("Lead provider partners")
      end

      it "renders table headers" do
        expect(page).to have_content("Year")
        expect(page).to have_content("Lead providers")
        expect(page).to have_content("Action")
      end

      it "renders contract periods with lead providers" do
        expect(page).to have_content("2024")
        expect(page).to have_content("2025")
        expect(page).to have_content("Lead Provider One, Lead Provider Two")
        expect(page).to have_content("Lead Provider Three")
      end

      it "renders change links with correct parameters" do
        change_links = page.all("a", text: "Change")
        expect(change_links.size).to eq(2)

        expect(change_links.first[:href]).to include("year=2024")
        expect(change_links.first[:href]).to include("page=2")
        expect(change_links.first[:href]).to include("q=search")

        expect(change_links.last[:href]).to include("year=2025")
        expect(change_links.last[:href]).to include("page=2")
        expect(change_links.last[:href]).to include("q=search")
      end
    end

    context "when page and q are nil" do
      let(:component) do
        described_class.new(
          lead_provider_partnerships: partnerships,
          delivery_partner:
        )
      end

      before { render_inline(component) }

      it "renders change links without page/q parameters" do
        change_links = page.all("a", text: "Change")
        expect(change_links.first[:href]).to include("year=2024")
        expect(change_links.first[:href]).not_to include("page=")
        expect(change_links.first[:href]).not_to include("q=")
      end
    end
  end

  describe "#render?" do
    context "when there are partnerships" do
      it "returns true" do
        expect(component.render?).to be true
      end
    end

    context "when there are no partnerships" do
      let(:component) do
        described_class.new(
          lead_provider_partnerships: [],
          delivery_partner:
        )
      end

      it "returns false" do
        expect(component.render?).to be false
      end
    end
  end

  describe "private methods" do
    describe "#grouped_partnerships" do
      it "groups partnerships by contract period" do
        grouped = component.send(:grouped_partnerships)
        expect(grouped.keys).to contain_exactly(contract_period_2024, contract_period_2025)
        expect(grouped[contract_period_2024].size).to eq(2)
        expect(grouped[contract_period_2025].size).to eq(1)
      end
    end

    describe "#lead_provider_names" do
      it "joins lead provider names with commas" do
        partnerships_2024 = partnerships.select { |p| p.contract_period.year == 2024 }
        names = component.send(:lead_provider_names, partnerships_2024)
        expect(names).to eq("Lead Provider One, Lead Provider Two")
      end
    end

    describe "#change_link_path" do
      it "generates correct path with parameters" do
        render_inline(component) # Render first to make helpers available
        path = component.send(:change_link_path, contract_period_2024)
        expect(path).to include("/admin/organisations/delivery-partners/#{delivery_partner.id}/edit")
        expect(path).to include("year=2024")
        expect(path).to include("page=2")
        expect(path).to include("q=search")
      end
    end
  end
end
