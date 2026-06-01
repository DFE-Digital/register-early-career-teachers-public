RSpec.describe "admin/finance/active_lead_providers/contracts/index.html.erb" do
  let(:contract_period) { FactoryBot.create(:contract_period) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:) }

  let(:contract) { FactoryBot.create(:contract, active_lead_provider:) }
  let(:ecf_contract) { FactoryBot.create(:contract, :for_ecf, active_lead_provider:) }
  let(:contracts) { [contract, ecf_contract] }

  before do
    assign(:active_lead_provider, active_lead_provider)
    assign(:contracts, contracts)
    assign(:breadcrumbs, {
      "Finance" => admin_finance_path,
      "Contract periods" => admin_contract_periods_path,
      contract_period.year.to_s => admin_contract_period_path(contract_period),
      active_lead_provider.lead_provider_name => admin_contract_period_active_lead_providers_path(contract_period),
    })
  end

  it "renders the title, breadcrumbs, description and contract fee structures" do
    render

    expect(view.content_for(:page_title)).to eq("Contracts")
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Finance", href: admin_finance_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Contract periods", href: admin_contract_periods_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link(active_lead_provider.contract_period_year.to_s, href: admin_contract_period_path(contract_period))
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link(active_lead_provider.lead_provider_name, href: admin_contract_period_active_lead_providers_path(contract_period))

    expect(rendered).to have_content("Contracts for #{active_lead_provider.lead_provider_name} in the #{contract_period.year} contract period:")

    expect(rendered).to have_css(".govuk-table", count: 2)
    ["Band", "Min", "Max", "Payment amount per participant"].each do |header|
      expect(rendered).to have_css(".govuk-table__header", text: header)
    end

    expect(rendered).to have_content("Band A")
    expect(rendered).to have_content("Band B")
    expect(rendered).to have_content("Band C")
    contract.banded_fee_structure.bands.each do |band|
      expect(rendered).to have_content(band.min_declarations.to_s)
      expect(rendered).to have_content(band.max_declarations.to_s)
    end
  end

  context "when there are no contracts" do
    let(:contracts) { [] }

    it "displays a message informing me there are no contracts" do
      render

      expect(rendered).to have_content("No contracts found")
      expect(rendered).not_to have_css(".govuk-table")
    end
  end
end
