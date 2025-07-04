RSpec.describe 'admin/finance/statements/index.html.erb' do
  let(:raw_statements) { FactoryBot.create_list(:statement, 3) }
  let(:pagy) { Pagy.new(count: raw_statements.count, limit: 10, page: 1) }
  let(:statements) { Admin::StatementPresenter.wrap(raw_statements) }
  let(:locals) { { filter_params: {} } }

  before do
    assign(:statements, statements)
    assign(:pagy, pagy)
  end

  it 'has title Statements' do
    render(locals:)

    expect(view.content_for(:page_title)).to eq('Statements')
  end

  it 'shows a table of statements' do
    render(locals:)

    expect(rendered).to have_css('.govuk-table')
  end

  it 'has a link to each statement' do
    render(locals:)

    presented_statements = Admin::StatementPresenter.wrap(raw_statements)
    presented_statements.each do |s|
      link_text = "View statement for #{s.lead_provider_name} in #{s.month_and_year}"
      expect(rendered).to have_link(link_text, href: admin_finance_statement_path(s))
    end
  end

  it 'has the right number of rows' do
    render(locals:)

    expect(rendered).to have_css('.govuk-table > .govuk-table__body > tr', count: 3)
  end

  context 'when there are no statements' do
    let(:raw_statements) { [] }

    it 'displays a message informing me there are no statements to display' do
      render(locals:)

      expect(rendered).to have_content('No financial statements found')
    end
  end
end
