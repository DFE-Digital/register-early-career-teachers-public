RSpec.describe "admin/finance/active_lead_providers/contracts/edit.html.erb" do
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

    expect(view.content_for(:page_title)).to eq("Edit contract")
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Back", href: contract_path)

    expect(rendered).to have_selector("form[action='#{contract_path}']")
    expect(rendered).to have_selector("input[name='_method'][value='patch']", visible: :all)

    expect(rendered).to have_css("legend", text: "Contract type")
    expect(rendered).to have_css("h2", text: "Flat rate fee structure")
    expect(rendered).to have_css("h2", text: "Banded fee structure")
    expect(rendered).to have_css("h3", text: "Bands")

    expect(rendered).to have_button("Save contract")
  end
end
