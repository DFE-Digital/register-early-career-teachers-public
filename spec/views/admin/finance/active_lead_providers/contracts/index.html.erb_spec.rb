RSpec.describe "admin/finance/active_lead_providers/contracts/index.html.erb" do
  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:) }
  let(:contract) { FactoryBot.create(:contract, active_lead_provider:) }

  before do
    assign(:active_lead_provider, active_lead_provider)
    assign(:contracts, [contract])
    assign(:breadcrumbs, {
      "Finance" => admin_finance_path,
      "Contract periods" => admin_contract_periods_path,
      contract_period.year.to_s => admin_contract_period_path(contract_period),
      active_lead_provider.lead_provider_name => admin_contract_period_active_lead_providers_path(contract_period),
    })
  end

  it "renders the title, breadcrumbs, description and contracts table" do
    render

    expect(view.content_for(:page_title)).to eq("Contracts")
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Finance", href: admin_finance_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Contract periods", href: admin_contract_periods_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link(contract_period.year.to_s, href: admin_contract_period_path(contract_period))
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link(active_lead_provider.lead_provider_name, href: admin_contract_period_active_lead_providers_path(contract_period))

    expect(rendered).to have_content("Contracts for #{active_lead_provider.lead_provider_name} in the #{contract_period.year} contract period")

    expect(rendered).to have_css(".govuk-table")
    expect(rendered).to have_link(
      contract.contract_type.humanize.upcase,
      href: admin_contract_period_active_lead_provider_contract_path(contract_period, active_lead_provider, contract)
    )
  end

  context "when the contract period is editable" do
    it "shows a delete button per contract and an add contract link" do
      render

      expect(rendered).to have_button("Delete")
      expect(rendered).to have_link("Add contract")
    end
  end

  context "when the contract period is payments frozen" do
    let(:contract_period) { FactoryBot.create(:contract_period, :with_payments_frozen) }

    it "does not show delete buttons or an add contract link" do
      render

      expect(rendered).not_to have_button("Delete")
      expect(rendered).not_to have_link("Add contract")
    end
  end

  context "when there are no contracts" do
    before { assign(:contracts, []) }

    it "displays a no contracts message and no table" do
      render

      expect(rendered).to have_content("No contracts found")
      expect(rendered).not_to have_css(".govuk-table")
    end
  end
end
