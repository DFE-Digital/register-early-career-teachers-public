RSpec.describe "admin/finance/active_lead_providers/contracts/show.html.erb" do
  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:) }
  let(:contract) { FactoryBot.create(:contract, active_lead_provider:) }

  before do
    assign(:active_lead_provider, active_lead_provider)
    assign(:contract, contract)
    assign(:breadcrumbs, {
      "Finance" => admin_finance_path,
      "Contract periods" => admin_contract_periods_path,
      contract_period.year.to_s => admin_contract_period_path(contract_period),
      active_lead_provider.lead_provider_name => admin_contract_period_active_lead_providers_path(contract_period),
      "Contracts" => admin_contract_period_active_lead_provider_contracts_path(contract_period, active_lead_provider),
    })
  end

  it "renders the title, breadcrumbs and contract details" do
    render

    expect(view.content_for(:page_title)).to eq(contract.description)
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Finance", href: admin_finance_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Contract periods", href: admin_contract_periods_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link(contract_period.year.to_s, href: admin_contract_period_path(contract_period))
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link(active_lead_provider.lead_provider_name, href: admin_contract_period_active_lead_providers_path(contract_period))
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Contracts", href: admin_contract_period_active_lead_provider_contracts_path(contract_period, active_lead_provider))

    expect(rendered).to have_css(".govuk-summary-list__key", text: "Contract type")
    expect(rendered).to have_css(".govuk-summary-list__value", text: contract.contract_type.humanize.upcase)
    expect(rendered).to have_css(".govuk-summary-list__key", text: "Created")
    expect(rendered).to have_css(".govuk-summary-list__key", text: "VAT rate")
    expect(rendered).to have_css(".govuk-summary-list__key", text: "Statement period")

    expect(rendered).to have_css("h2", text: "Flat rate fee structure")
    expect(rendered).to have_css("h2", text: "Banded fee structure")
  end

  context "when the contract has no flat rate fee structure" do
    let(:contract) { FactoryBot.create(:contract, :for_ecf, active_lead_provider:) }

    it "shows not applicable for flat rate fee structure" do
      render
      expect(rendered).to have_content("Not applicable")
    end
  end

  context "when the contract period is not payments frozen" do
    it "shows edit and delete buttons" do
      render

      expect(rendered).to have_link("Edit")
      expect(rendered).to have_button("Delete")
    end
  end

  context "when the contract period is payments frozen" do
    let(:contract_period) { FactoryBot.create(:contract_period, :with_payments_frozen) }

    it "does not show edit or delete buttons" do
      render

      expect(rendered).not_to have_link("Edit")
      expect(rendered).not_to have_button("Delete")
    end
  end
end
