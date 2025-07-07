RSpec.describe 'admin/finance/statements/show.html.erb' do
  let(:lead_provider) { create(:lead_provider, name: "Some LP") }
  let(:active_lead_provider) { create(:active_lead_provider, lead_provider:) }
  let(:statement_rec) { create(:statement, active_lead_provider:, month: 5, year: 2023) }
  let(:statement) { Admin::StatementPresenter.new(statement_rec) }

  before do
    assign(:statement, statement)
  end

  it 'has title with lead provider name and statement month and year' do
    render

    expect(view.content_for(:page_title)).to eq('Some LP - May 2023')
  end

  it 'displays the statement information in a summary list' do
    render

    expect(rendered).to have_css('.govuk-summary-list')
  end

  it 'contains values relevant to the statement'
end
