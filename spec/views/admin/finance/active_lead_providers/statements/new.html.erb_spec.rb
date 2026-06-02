RSpec.describe "admin/finance/active_lead_providers/statements/new.html.erb" do
  let(:contract_period) do
    FactoryBot.create(:contract_period, year: 2099, started_on: Date.new(2099, 6, 1), finished_on: Date.new(2100, 5, 31))
  end
  let(:lead_provider) { FactoryBot.create(:lead_provider, name: "Lead Provider 1") }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:, lead_provider:) }
  let!(:contract) { FactoryBot.create(:contract, :for_ittecf_ectp, active_lead_provider:) }
  let(:statement) { Statement.new }

  let(:index_path) { admin_contract_period_active_lead_provider_statements_path(contract_period, active_lead_provider) }

  before do
    assign(:active_lead_provider, active_lead_provider)
    assign(:statement, statement)
  end

  it "renders the new statement form with its fields and a back link" do
    render

    expect(view.content_for(:page_title)).to eq("Add statement")
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Back", href: index_path)

    expect(rendered).to have_selector("form[action='#{index_path}']")
    expect(rendered).to have_button("Save")

    expect(rendered).to have_css("select[name='statement[contract_id]'] option[value='#{contract.id}']")
    expect(rendered).to have_css("input[type='radio'][name='statement[fee_type]'][value='output']")
    expect(rendered).to have_css("input[type='radio'][name='statement[fee_type]'][value='service']")
    expect(rendered).to have_css("select[name='statement[month]'] option[value='11']", text: "November")
    expect(rendered).to have_css("legend", text: "Deadline date")
    expect(rendered).to have_css("legend", text: "Payment date")

    (contract_period.year..(contract_period.year + 4)).each do |year|
      expect(rendered).to have_css("select[name='statement[year]'] option[value='#{year}']", text: year.to_s)
    end
    expect(rendered).to have_css("select[name='statement[year]'] option", count: 6) # blank + 5 years
  end

  context "when the statement is invalid" do
    let(:statement) { Statement.new.tap(&:valid?) }

    it "prefixes the page title with 'Error:' and renders an error summary" do
      render

      expect(view.content_for(:page_title)).to start_with("Error:")
      expect(view.content_for(:error_summary)).to have_css(".govuk-error-summary")
    end
  end
end
