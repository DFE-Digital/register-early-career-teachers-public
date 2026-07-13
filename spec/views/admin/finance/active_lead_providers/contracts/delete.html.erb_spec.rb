RSpec.describe "admin/finance/active_lead_providers/contracts/delete.html.erb" do
  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:) }
  let(:contract) { FactoryBot.create(:contract, active_lead_provider:) }
  let(:contract_path) do
    admin_contract_period_active_lead_provider_contract_path(contract_period, active_lead_provider, contract)
  end

  before do
    assign(:active_lead_provider, active_lead_provider)
    assign(:contract, contract)
  end

  it "renders" do
    render

    expect(view.content_for(:page_title)).to eq("Delete contract")
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Back", href: contract_path)

    expect(rendered).to have_css(".govuk-warning-text", text: "Are you sure you want to delete this contract?")
    expect(rendered).to have_css(".govuk-warning-text", text: "This action cannot be undone.")

    expect(rendered).to have_button("Delete contract")
    expect(rendered).to have_link("Cancel", href: contract_path)
  end
end
