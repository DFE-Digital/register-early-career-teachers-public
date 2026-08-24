RSpec.describe "admin/finance/framework_agreements/contracts/new.html.erb" do
  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:framework_agreement) { FactoryBot.create(:framework_agreement, contract_period:) }
  let(:contract) { Contract.new }
  let(:contracts_path) do
    admin_contract_period_framework_agreement_contracts_path(contract_period, framework_agreement)
  end

  before do
    assign(:framework_agreement, framework_agreement)
    assign(:contract, contract)
  end

  it "renders" do
    render

    expect(view.content_for(:page_title)).to eq("Add contract")
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Back", href: contracts_path)

    expect(rendered).to have_selector("form[action='#{contracts_path}']")

    expect(rendered).to have_css("legend", text: "Contract type")
    expect(rendered).to have_css("h2", text: "Flat rate fee structure")
    expect(rendered).to have_css("h2", text: "Banded fee structure")

    expect(rendered).to have_button("Save contract")
  end
end
