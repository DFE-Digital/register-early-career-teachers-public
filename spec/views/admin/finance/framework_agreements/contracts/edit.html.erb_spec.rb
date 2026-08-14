RSpec.describe "admin/finance/framework_agreements/contracts/edit.html.erb" do
  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:framework_agreement) { FactoryBot.create(:framework_agreement, contract_period:) }
  let(:contract) { FactoryBot.create(:contract, framework_agreement:) }

  let(:contract_path) do
    admin_contract_period_framework_agreement_contract_path(contract_period, framework_agreement, contract)
  end

  before do
    assign(:framework_agreement, framework_agreement)
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
