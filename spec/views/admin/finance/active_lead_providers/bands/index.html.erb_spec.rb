RSpec.describe "admin/finance/active_lead_providers/bands/index.html.erb" do
  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:framework_agreement) { FactoryBot.create(:framework_agreement, contract_period:) }
  let(:band_a) { FactoryBot.create(:framework_agreement_band, framework_agreement:, capacity: 500) }
  let(:band_b) { FactoryBot.create(:framework_agreement_band, framework_agreement:, capacity: 1500) }

  before do
    assign(:framework_agreement, framework_agreement)
    assign(:bands, [band_a, band_b])
    assign(:breadcrumbs, {
      "Finance" => admin_finance_path,
      "Contract periods" => admin_contract_periods_path,
      contract_period.year.to_s => admin_contract_period_path(contract_period),
      framework_agreement.lead_provider_name => admin_contract_period_active_lead_provider_bands_path(contract_period, framework_agreement),
    })
  end

  it "renders the title, breadcrumbs, description and contracts table" do
    render

    expect(view.content_for(:page_title)).to eq("Bands")
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Finance", href: admin_finance_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Contract periods", href: admin_contract_periods_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link(contract_period.year.to_s, href: admin_contract_period_path(contract_period))
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link(framework_agreement.lead_provider_name, href: admin_contract_period_active_lead_provider_bands_path(contract_period, framework_agreement))

    expect(rendered).to have_content("Bands for #{framework_agreement.lead_provider_name} in the #{contract_period.year} contract period")

    expect(rendered).to have_css(".govuk-table")
    expect(rendered).to have_link(
      "Change Band B",
      href: edit_admin_contract_period_active_lead_provider_band_path(contract_period, framework_agreement, band_b)
    )
  end

  context "when the contract period is editable" do
    it "shows a delete button and an add band link" do
      render

      expect(rendered).to have_button("Delete Band B")
      expect(rendered).to have_link("Add band")
    end
  end

  context "when the contract period is not editable" do
    it "does not show delete button or add band link" do
      travel_to contract_period.started_on do
        render

        expect(rendered).not_to have_button("Delete Band B")
        expect(rendered).not_to have_link("Add band")
      end
    end
  end

  context "when the provider has a contract" do
    before do
      FactoryBot.create(:contract, framework_agreement:)
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
