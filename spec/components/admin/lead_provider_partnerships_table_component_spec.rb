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

  let(:partnerships_2024) do
    [
      FactoryBot.create(:lead_provider_delivery_partnership, delivery_partner:, active_lead_provider: active_lead_provider_1),
      FactoryBot.create(:lead_provider_delivery_partnership, delivery_partner:, active_lead_provider: active_lead_provider_2)
    ]
  end

  let(:partnerships_2025) do
    [
      FactoryBot.create(:lead_provider_delivery_partnership, delivery_partner:, active_lead_provider: active_lead_provider_3)
    ]
  end

  let(:contract_period_partnerships) do
    [
      { contract_period: contract_period_2024, partnerships: partnerships_2024 },
      { contract_period: contract_period_2025, partnerships: partnerships_2025 }
    ]
  end

  let(:component) do
    described_class.new(
      contract_period_partnerships:,
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

        expect(change_links.first[:href]).to include("/2024/new")
        expect(change_links.first[:href]).to include("page=2")
        expect(change_links.first[:href]).to include("q=search")

        expect(change_links.last[:href]).to include("/2025/new")
        expect(change_links.last[:href]).to include("page=2")
        expect(change_links.last[:href]).to include("q=search")
      end
    end

    context "when some contract periods have no partnerships" do
      let(:contract_period_partnerships) do
        [
          { contract_period: contract_period_2024, partnerships: partnerships_2024 },
          { contract_period: contract_period_2025, partnerships: [] }
        ]
      end

      before { render_inline(component) }

      it "renders empty cells for contract periods without partnerships" do
        expect(page).to have_content("2024")
        expect(page).to have_content("2025")
        expect(page).to have_content("Lead Provider One, Lead Provider Two")

        # Find the row for 2025 and check it has an empty lead providers cell
        rows = page.all("tbody tr")
        expect(rows.size).to eq(2)

        # The second row should be for 2025 with empty partnerships
        row_2025 = rows.last
        cells = row_2025.all("td")
        expect(cells[0]).to have_content("2025") # Year column
        expect(cells[1].text.strip).to be_empty # Lead providers column should be empty
        expect(cells[2]).to have_link("Change") # Action column
      end
    end

    context "when page and q are nil" do
      let(:component) do
        described_class.new(
          contract_period_partnerships:,
          delivery_partner:
        )
      end

      before { render_inline(component) }

      it "renders change links without page/q parameters" do
        change_links = page.all("a", text: "Change")
        expect(change_links.first[:href]).to include("/2024/new")
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

    context "when there are no contract periods" do
      let(:component) do
        described_class.new(
          contract_period_partnerships: [],
          delivery_partner:
        )
      end

      it "returns false" do
        expect(component.render?).to be false
      end
    end
  end

  describe "private methods" do
    describe "#lead_provider_names" do
      it "joins lead provider names with commas when partnerships exist" do
        names = component.send(:lead_provider_names, partnerships_2024)
        expect(names).to eq("Lead Provider One, Lead Provider Two")
      end

      it "returns empty string when no partnerships exist" do
        names = component.send(:lead_provider_names, [])
        expect(names).to eq("")
      end
    end

    describe "#change_link_path" do
      it "generates correct path with parameters" do
        render_inline(component) # Render first to make helpers available
        path = component.send(:change_link_path, contract_period_2024)
        expect(path).to include("/admin/organisations/delivery-partners/#{delivery_partner.id}/2024/new")
        expect(path).to include("page=2")
        expect(path).to include("q=search")
      end
    end
  end
end
