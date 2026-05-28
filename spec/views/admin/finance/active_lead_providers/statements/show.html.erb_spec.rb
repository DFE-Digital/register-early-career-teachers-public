RSpec.describe "admin/finance/active_lead_providers/statements/show.html.erb" do
  let(:contract_period) do
    FactoryBot.create(:contract_period, year: 2099, started_on: Date.new(2099, 6, 1), finished_on: Date.new(2100, 5, 31))
  end
  let(:lead_provider) { FactoryBot.create(:lead_provider, name: "Lead Provider 1") }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:, lead_provider:) }
  let(:statement) { FactoryBot.create(:statement, :open, :output_fee, active_lead_provider:, month: 11, year: 2099) }

  let(:index_path) { admin_contract_period_active_lead_provider_statements_path(contract_period, active_lead_provider) }
  let(:edit_path) { edit_admin_contract_period_active_lead_provider_statement_path(contract_period, active_lead_provider, statement) }
  let(:delete_path) { delete_admin_contract_period_active_lead_provider_statement_path(contract_period, active_lead_provider, statement) }

  before do
    assign(:active_lead_provider, active_lead_provider)
    assign(:statement, statement)
  end

  it "renders the statement details, heading, back link and enabled actions" do
    render

    expect(view.content_for(:page_title)).to eq("Statement #{Statements::Period.for(statement)}")
    expect(view.content_for(:page_caption)).to include(lead_provider.name)
    expect(view.content_for(:page_header)).to include(Statements::Period.for(statement))
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Back", href: index_path)

    ["Period", "Contract", "Fee type", "Status", "Deadline date", "Payment date"].each do |key|
      expect(rendered).to have_css(".govuk-summary-list__key", text: key)
    end
    expect(rendered).to have_css(".govuk-tag.govuk-tag--blue", text: "Open")

    expect(rendered).to have_link("Edit statement", href: edit_path)
    expect(rendered).to have_link("Delete statement", href: delete_path)
    expect(rendered).not_to have_selector("a[aria-disabled='true']")
  end

  context "when the contract period has started" do
    let(:contract_period) do
      FactoryBot.create(:contract_period, year: 2020, started_on: Date.new(2020, 6, 1), finished_on: Date.new(2021, 5, 31))
    end
    let(:statement) { FactoryBot.create(:statement, :open, :output_fee, active_lead_provider:, month: 11, year: 2020) }

    it "renders the Edit and Delete buttons in a disabled state" do
      render

      expect(rendered).to have_selector("a[disabled], a[aria-disabled='true']", text: "Edit statement")
      expect(rendered).to have_selector("a[disabled], a[aria-disabled='true']", text: "Delete statement")
    end
  end
end
