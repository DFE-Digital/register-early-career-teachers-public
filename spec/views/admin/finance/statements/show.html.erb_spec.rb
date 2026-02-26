RSpec.describe "admin/finance/statements/show.html.erb" do
  let(:lead_provider) { FactoryBot.create(:lead_provider, name: "Some LP") }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:) }
  let(:statement_rec) { FactoryBot.create(:statement, active_lead_provider:, year: 2025, month: 9, deadline_date:, payment_date:) }
  let(:deadline_date) { Date.new(2025, 9, 30) }
  let(:payment_date) { Date.new(2025, 10, 15) }
  let(:statement) { Admin::StatementPresenter.new(statement_rec) }

  before do
    assign(:statement, statement)
  end

  it "has title with lead provider name and statement month and year" do
    render

    expect(rendered).to have_css(".govuk-caption-l", text: "Some LP")
    expect(rendered).to have_css(".govuk-heading-m", text: "September 2025")
  end

  it "displays the statement dates and summary information in a table" do
    render
    expect(rendered).to have_css(".govuk-heading-m", text: "15 October 2025")
    expect(rendered).to have_css(".govuk-heading-m", text: "30 September 2025")
    expect(rendered).to have_css(".govuk-table", text: "VAT")
  end
end
