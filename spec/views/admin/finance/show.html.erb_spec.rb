RSpec.describe "admin/finance/show.html.erb" do
  it "links to the statements page" do
    render

    expect(rendered).to have_link("Statements", href: admin_finance_statements_path)
  end

  it "links to the search declarations page" do
    render

    expect(rendered).to have_link("Search declarations", href: admin_search_declarations_path)
  end

  context "with finance contract periods enabled", :enable_finance_contract_periods do
    it "links to the contract periods page" do
      render

      expect(rendered).to have_link("Contract periods", href: admin_contract_periods_path)
    end
  end

  context "with finance contract periods disabled" do
    it "does not link to the contract periods page" do
      render

      expect(rendered).not_to have_link("Contract periods", href: admin_contract_periods_path)
    end
  end
end
