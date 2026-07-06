RSpec.describe "admin/finance/active_lead_providers/bands/index.html.erb" do
  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:) }
  let(:band_a) { FactoryBot.create(:active_lead_provider_band, active_lead_provider:, capacity: 500) }
  let(:band_b) { FactoryBot.create(:active_lead_provider_band, active_lead_provider:, capacity: 1500) }

  before do
    assign(:active_lead_provider, active_lead_provider)
    assign(:bands, [band_a, band_b])
    assign(:breadcrumbs, {
      "Finance" => admin_finance_path,
      "Contract periods" => admin_contract_periods_path,
      contract_period.year.to_s => admin_contract_period_path(contract_period),
      active_lead_provider.lead_provider_name => admin_contract_period_active_lead_provider_bands_path(contract_period, active_lead_provider),
    })
  end

  it "renders the title, breadcrumbs, description and contracts table" do
    render

    expect(view.content_for(:page_title)).to eq("Bands")
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Finance", href: admin_finance_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Contract periods", href: admin_contract_periods_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link(contract_period.year.to_s, href: admin_contract_period_path(contract_period))
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link(active_lead_provider.lead_provider_name, href: admin_contract_period_active_lead_provider_bands_path(contract_period, active_lead_provider))

    expect(rendered).to have_content("Bands for #{active_lead_provider.lead_provider_name} in the #{contract_period.year} contract period")

    expect(rendered).to have_css(".govuk-table")
    expect(rendered).to have_link(
      "Change Band B",
      href: edit_admin_contract_period_active_lead_provider_band_path(contract_period, active_lead_provider, band_b)
    )
  end

  context "when the contract period is editable" do
    it "shows a delete link and an add band link" do
      render

      expect(rendered).to have_link("Delete Band B")
      expect(rendered).to have_link("Add band")
    end
  end

  context "when the contract period is not editable" do
    it "does not show delete or add band links" do
      travel_to contract_period.started_on do
        render

        expect(rendered).not_to have_link("Delete Band B")
        expect(rendered).not_to have_link("Add band")
      end
    end
  end

  context "when the provider has a contract" do
    before do
      FactoryBot.create(:contract, active_lead_provider:)
    end

    it "does not show delete or add band links" do
      render

      expect(rendered).not_to have_link("Delete Band B")
      expect(rendered).not_to have_link("Add band")
    end
  end

  context "when there are no bands" do
    before { assign(:bands, []) }

    it "displays a no bands message and no table" do
      render

      expect(rendered).to have_content("No bands found")
      expect(rendered).not_to have_css(".govuk-table")
    end
  end
end
