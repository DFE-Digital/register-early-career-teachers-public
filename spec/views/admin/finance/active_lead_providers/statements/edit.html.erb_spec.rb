RSpec.describe "admin/finance/active_lead_providers/statements/edit.html.erb" do
  let(:contract_period) do
    FactoryBot.create(:contract_period, year: 2099, started_on: Date.new(2099, 6, 1), finished_on: Date.new(2100, 5, 31))
  end
  let(:lead_provider) { FactoryBot.create(:lead_provider, name: "Lead Provider 1") }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:, lead_provider:) }
  let(:statement) { FactoryBot.create(:statement, :open, :output_fee, active_lead_provider:, month: 11, year: 2099) }

  let(:statement_path) { admin_contract_period_active_lead_provider_statement_path(contract_period, active_lead_provider, statement) }

  before do
    assign(:active_lead_provider, active_lead_provider)
    assign(:statement, statement)
  end

  it "renders the prefilled edit form with a back link" do
    render

    expect(view.content_for(:page_title)).to eq("Edit statement")
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Back", href: statement_path)

    expect(rendered).to have_selector("form[action='#{statement_path}']")
    expect(rendered).to have_selector("input[name='_method'][value='patch']", visible: :all)
    expect(rendered).to have_button("Save")

    expect(rendered).to have_css("select[name='statement[month]'] option[value='11'][selected]")
    expect(rendered).to have_css("select[name='statement[year]'] option[value='2099'][selected]")
    expect(rendered).to have_css("select[name='statement[contract_id]'] option[value='#{statement.contract_id}'][selected]")
  end

  context "when the statement is invalid" do
    before do
      statement.month = 99
      statement.validate
    end

    it "prefixes the page title with 'Error:' and renders an error summary" do
      render

      expect(view.content_for(:page_title)).to start_with("Error:")
      expect(view.content_for(:error_summary)).to have_css(".govuk-error-summary")
    end
  end
end
