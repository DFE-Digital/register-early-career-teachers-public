RSpec.describe "admin/finance/framework_agreements/statements/delete.html.erb" do
  let(:contract_period) do
    FactoryBot.create(:contract_period, year: 2099, started_on: Date.new(2099, 6, 1), finished_on: Date.new(2100, 5, 31))
  end
  let(:lead_provider) { FactoryBot.create(:lead_provider, name: "Lead Provider 1") }
  let(:framework_agreement) { FactoryBot.create(:framework_agreement, contract_period:, lead_provider:) }
  let(:statement) { FactoryBot.create(:statement, :open, :output_fee, framework_agreement:, month: 11, year: 2099) }

  let(:statement_path) { admin_contract_period_framework_agreement_statement_path(contract_period, framework_agreement, statement) }

  before do
    assign(:framework_agreement, framework_agreement)
    assign(:statement, statement)
  end

  it "renders the delete confirmation with statement details and a back link" do
    render

    expect(view.content_for(:page_title)).to eq("Delete statement")
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Back", href: statement_path)

    expect(rendered).to have_css(".govuk-summary-list__key", text: "Period")
    expect(rendered).to have_css(".govuk-summary-list__key", text: "Contract")
    expect(rendered).to have_css(".govuk-summary-list__key", text: "Fee type")
    expect(rendered).to have_css(".govuk-summary-list__value", text: statement.contract.description)

    expect(rendered).to have_content("Are you sure you want to delete this statement?")
    expect(rendered).to have_selector("form[action='#{statement_path}']")
    expect(rendered).to have_selector("input[name='_method'][value='delete']", visible: :all)
    expect(rendered).to have_button("Delete statement")
    expect(rendered).to have_link("Cancel", href: statement_path)
  end

  context "when the statement has declarations" do
    before { allow(statement).to receive(:referenced_by_declarations?).and_return(true) }

    it "explains it cannot be deleted and hides the delete button" do
      render

      expect(rendered).to have_content("This statement has declarations and cannot be deleted")
      expect(rendered).not_to have_button("Delete statement")
      expect(rendered).to have_link("Return to statement", href: statement_path)
    end
  end
end
