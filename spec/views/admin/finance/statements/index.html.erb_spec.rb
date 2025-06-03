RSpec.describe 'admin/finance/statements/index.html.erb' do
  let(:raw_statements) { FactoryBot.create_list(:statement, 3) }
  let(:pagy) { pagy_array(raw_statements, items: 10, page: 1) }
  let(:statements) { Admin::StatementPresenter.wrap(raw_statements) }

  before do
    assign(:statements, statements)
  end

  it 'has title Statements' do
    render

    expect(view.content_for(:page_title)).to eq('Statements')
  end

  it 'shows a table of statements' do
    render

    expect(rendered).to have_css('.govuk-table')
  end

  it 'has a link to each statement' do
    render

    raw_statements.each { |s| expect(rendered).to have_link('View', href: admin_finance_statement_path(s)) }
  end

  it 'has the right number of rows' do
    render

    expect(rendered).to have_css('.govuk-table > .govuk-table__body > tr', count: 3)
  end

  context 'when there are no statements' do
    let(:raw_statements) { [] }

    it 'displays a message informing me there are no statements to display' do
      render

      expect(rendered).to have_content('There are no statements')
    end
  end
end
