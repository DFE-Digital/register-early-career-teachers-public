RSpec.describe "admin/finance/active_lead_providers/statements/index.html.erb" do
  let(:contract_period) do
    FactoryBot.create(:contract_period, year: 2099, started_on: Date.new(2099, 6, 1), finished_on: Date.new(2100, 5, 31))
  end
  let(:lead_provider) { FactoryBot.create(:lead_provider, name: "Lead Provider 1") }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:, lead_provider:) }

  let(:november_statement) do
    FactoryBot.create(:statement, :open, :output_fee, active_lead_provider:, month: 11, year: 2099)
  end
  let(:december_statement) do
    FactoryBot.create(:statement, :paid, :service_fee, active_lead_provider:, month: 12, year: 2099)
  end
  let(:raw_statements) { [november_statement, december_statement] }
  let(:pagy) { Pagy.new(count: raw_statements.count, limit: 10, page: 1) }

  before do
    assign(:active_lead_provider, active_lead_provider)
    assign(:statements, raw_statements)
    assign(:pagy, pagy)
    assign(:breadcrumbs, {
      "Finance" => admin_finance_path,
      "Contract periods" => admin_contract_periods_path,
      contract_period.year.to_s => admin_contract_period_path(contract_period),
      lead_provider.name => nil,
    })
  end

  it "has the page title 'Statements'" do
    render

    expect(view.content_for(:page_title)).to eq("Statements")
  end

  it "renders the breadcrumbs" do
    render

    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Finance", href: admin_finance_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Contract periods", href: admin_contract_periods_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link(contract_period.year.to_s, href: admin_contract_period_path(contract_period))
    expect(view.content_for(:backlink_or_breadcrumb)).to include(lead_provider.name)
  end

  it "describes what the user is looking at" do
    render

    expect(rendered).to have_content("Statements for #{lead_provider.name} in the #{contract_period.year} contract period.")
  end

  it "renders a single table with the expected columns" do
    render

    expect(rendered).to have_css(".govuk-table", count: 1)
    ["Month", "Fee type", "Deadline date", "Payment date", "Status"].each do |header|
      expect(rendered).to have_css(".govuk-table__header", text: header)
    end
  end

  it "renders a row per statement with a stubbed month link, fee type, dates and status tag" do
    render

    expect(rendered).to have_css(".govuk-table > .govuk-table__body > tr", count: 2)

    expect(rendered).to have_link("November 2099", href: "#")
    expect(rendered).to have_link("December 2099", href: "#")

    expect(rendered).to have_content("Output")
    expect(rendered).to have_content("Service")

    expect(rendered).to have_css(".govuk-tag.govuk-tag--blue", text: "Open")
    expect(rendered).to have_css(".govuk-tag.govuk-tag--green", text: "Paid")

    expect(rendered).to have_content(november_statement.deadline_date.to_fs(:govuk))
    expect(rendered).to have_content(december_statement.payment_date.to_fs(:govuk))
  end

  it "renders statements in the order they are given (year/month ascending)" do
    render

    body = Capybara.string(rendered)
    rows = body.all(".govuk-table > .govuk-table__body > tr").map(&:text)

    expect(rows[0]).to include("November 2099")
    expect(rows[1]).to include("December 2099")
  end

  describe "the Add statement button" do
    context "when the contract period has not yet started" do
      it "renders an enabled button stubbed to '#'" do
        render

        expect(rendered).to have_link("Add statement", href: "#")
        expect(rendered).not_to have_selector("a[aria-disabled='true']", text: "Add statement")
      end
    end

    context "when the contract period has already started" do
      let(:contract_period) do
        FactoryBot.create(:contract_period, year: 2020, started_on: Date.new(2020, 6, 1), finished_on: Date.new(2021, 5, 31))
      end
      let(:november_statement) do
        FactoryBot.create(:statement, :open, :output_fee, active_lead_provider:, month: 11, year: 2020)
      end
      let(:december_statement) do
        FactoryBot.create(:statement, :paid, :service_fee, active_lead_provider:, month: 12, year: 2020)
      end

      it "renders the button in a disabled state" do
        render

        expect(rendered).to have_selector("a[disabled], a[aria-disabled='true']", text: "Add statement")
      end
    end
  end

  context "when there are no statements" do
    let(:raw_statements) { [] }

    it "displays a message informing me there are no statements" do
      render

      expect(rendered).to have_content("No statements found")
      expect(rendered).not_to have_css(".govuk-table")
    end
  end
end
