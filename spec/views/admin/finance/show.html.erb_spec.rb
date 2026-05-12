RSpec.describe "admin/finance/show.html.erb" do
  it "has a link to the statements page" do
    render

    expect(rendered).to have_link("Statements", href: admin_finance_statements_path)
  end

  it "has a link to the search declarations page" do
    render

    expect(rendered).to have_link("Search declarations", href: admin_search_declarations_path)
  end

  it "has a link to the contract periods page" do
    render

    expect(rendered).to have_link("Contract periods", href: admin_contract_periods_path)
  end
end
