RSpec.describe 'admin/finance/show.html.erb' do
  it 'has a link to the statements page' do
    render

    expect(rendered).to have_link('Statements', href: admin_finance_statements_path)
  end
end
