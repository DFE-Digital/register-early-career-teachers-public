RSpec.describe "admin/finance/contract_periods/index.html.erb" do
  let(:contract_periods) { FactoryBot.create_list(:contract_period, 3) }
  let(:pagy) { Pagy.new(count: contract_periods.count, limit: 5, page: 1) }

  before do
    assign(:contract_periods, contract_periods)
    assign(:pagy, pagy)
    assign(:breadcrumbs, {
      "Finance" => admin_finance_path,
      "Contract periods" => nil,
    })
  end

  it "has title Contract periods" do
    render

    expect(view.content_for(:page_title)).to eq("Contract periods")
  end

  it "shows a table of contract periods" do
    render

    expect(rendered).to have_css(".govuk-table")
  end

  it "renders breadcrumbs" do
    render

    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Finance", href: admin_finance_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to include("Contract periods")
    expect(view.content_for(:backlink_or_breadcrumb)).not_to have_link("Contract periods")
  end

  it "has the right number of rows" do
    render

    expect(rendered).to have_css(".govuk-table > .govuk-table__body > tr", count: 3)
  end

  it "renders an add contract period button" do
    render

    expect(rendered).to have_link("Add Contract period")
  end

  context "when there are no contract periods" do
    let(:contract_periods) { [] }

    it "displays a message informing me there are no contract periods to display" do
      render

      expect(rendered).to have_content("No contract periods found")
    end
  end
end
