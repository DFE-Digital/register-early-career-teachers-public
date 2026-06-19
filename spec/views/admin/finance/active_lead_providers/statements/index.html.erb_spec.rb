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
      lead_provider.name => admin_contract_period_active_lead_providers_path(contract_period),
    })
  end

  it "renders the title, breadcrumbs, description, statements table in order, and an enabled add button" do
    render

    expect(view.content_for(:page_title)).to eq("Statements")
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Finance", href: admin_finance_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Contract periods", href: admin_contract_periods_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link(contract_period.year.to_s, href: admin_contract_period_path(contract_period))
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link(lead_provider.name, href: admin_contract_period_active_lead_providers_path(contract_period))

    expect(rendered).to have_content("Statements for #{lead_provider.name} in the #{contract_period.year} contract period.")

    expect(rendered).to have_css(".govuk-table", count: 1)
    ["Month", "Fee type", "Deadline date", "Payment date", "Status"].each do |header|
      expect(rendered).to have_css(".govuk-table__header", text: header)
    end

    rows = Capybara.string(rendered).all(".govuk-table > .govuk-table__body > tr")
    expect(rows.count).to eq(2)
    expect(rows[0].text).to include("November 2099")
    expect(rows[1].text).to include("December 2099")
    expect(rendered).to have_link("November 2099", href: admin_contract_period_active_lead_provider_statement_path(contract_period, active_lead_provider, november_statement))
    expect(rendered).to have_content("Output")
    expect(rendered).to have_content("Service")
    expect(rendered).to have_css(".govuk-tag.govuk-tag--blue", text: "Open")
    expect(rendered).to have_css(".govuk-tag.govuk-tag--green", text: "Paid")
    expect(rendered).to have_content(november_statement.deadline_date.to_fs(:govuk))
    expect(rendered).to have_content(december_statement.payment_date.to_fs(:govuk))

    expect(rendered).to have_link("Add statement", href: new_admin_contract_period_active_lead_provider_statement_path(contract_period, active_lead_provider))
    expect(rendered).not_to have_selector("a[aria-disabled='true']", text: "Add statement")
  end

  context "when the contract period has already started but is not frozen" do
    let(:contract_period) do
      FactoryBot.create(:contract_period, year: 2020, started_on: Date.new(2020, 6, 1), finished_on: Date.new(2021, 5, 31))
    end

    it "renders the add button in an enabled state" do
      render

      expect(rendered).to have_link("Add statement", href: new_admin_contract_period_active_lead_provider_statement_path(contract_period, active_lead_provider))
      expect(rendered).not_to have_selector("a[aria-disabled='true']", text: "Add statement")
    end
  end

  context "when the contract period is frozen" do
    let(:contract_period) do
      FactoryBot.create(:contract_period, year: 2020, started_on: Date.new(2020, 6, 1), finished_on: Date.new(2021, 5, 31),
                                          payments_frozen_at: Time.zone.now)
    end

    it "renders the add button in a disabled state" do
      render

      expect(rendered).to have_selector("a[disabled], a[aria-disabled='true']", text: "Add statement")
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
