RSpec.describe "admin/finance/active_lead_providers/index.html.erb" do
  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:active_lead_providers) { FactoryBot.create_list(:active_lead_provider, 3, contract_period:) }
  let(:add_button_text) { "Add a lead provider" }
  let(:started_hint) { "This contract period has started, so active lead providers are no longer editable." }

  before do
    assign(:contract_period, contract_period)
    assign(:active_lead_providers, active_lead_providers)
    assign(:editable, !contract_period.started_on_or_before_today?)
    assign(:breadcrumbs, {
      "Finance" => admin_finance_path,
      "Contract periods" => admin_contract_periods_path,
      contract_period.year.to_s => admin_contract_period_path(contract_period),
    })
  end

  it "renders the title, breadcrumbs, table, counts, delete and add buttons, and no started hint" do
    render

    expect(view.content_for(:page_title)).to eq("Lead providers for #{contract_period.year}")
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Finance", href: admin_finance_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Contract periods", href: admin_contract_periods_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link(contract_period.year.to_s, href: admin_contract_period_path(contract_period))

    expect(rendered).to have_css("p.govuk-body", normalize_ws: true, text: "These lead providers are active for the #{contract_period.year} contract period (#{contract_period.started_on.to_fs(:govuk)} to #{contract_period.finished_on.to_fs(:govuk)}).")

    expect(rendered).to have_css(".govuk-table", count: 1)
    expect(rendered).to have_css(".govuk-table__head th", text: "Lead provider")
    expect(rendered).to have_css(".govuk-table__head th", text: "Contracts")
    expect(rendered).to have_css(".govuk-table__head th", text: "Statements")
    expect(rendered).to have_css(".govuk-table__head th", text: "Delivery partners")

    expect(rendered).to have_css(".govuk-table__body > tr", count: 3)
    active_lead_providers.each do |alp|
      expect(rendered).to have_css("tr", text: alp.lead_provider.name)
      expect(rendered).to have_css("tr", text: pluralize(alp.contracts.count, "contract"))
      expect(rendered).to have_css("tr", text: pluralize(alp.statements.count, "statement"))
      expect(rendered).to have_css("tr", text: pluralize(alp.delivery_partners.count, "delivery partner"))
    end

    expect(rendered).to have_css(".govuk-button--secondary", count: 3, text: "Remove")
    active_lead_providers.each do |alp|
      expect(rendered).to have_css(
        "form[action='#{admin_contract_period_active_lead_provider_path(contract_period, alp)}']"
      )
    end

    expect(rendered).to have_link(add_button_text, href: new_admin_contract_period_active_lead_provider_path(contract_period))

    expect(rendered).not_to have_content(started_hint)
  end

  context "when the contract period has started" do
    let(:contract_period) { FactoryBot.create(:contract_period, :current) }

    it "shows the started hint, hides delete and add buttons, and still renders the counts as links" do
      render

      expect(rendered).to have_css(".govuk-hint", text: started_hint)

      expect(rendered).not_to have_css(".govuk-button--secondary", text: "Remove")
      expect(rendered).not_to have_link(add_button_text)

      active_lead_providers.each do |alp|
        expect(rendered).to have_link(pluralize(alp.contracts.count, "contract"))
        expect(rendered).to have_link(pluralize(alp.statements.count, "statement"))
        expect(rendered).to have_link(pluralize(alp.delivery_partners.count, "delivery partner"))
      end
    end
  end

  context "when there are no active lead providers" do
    let(:active_lead_providers) { [] }

    it "displays an empty state message" do
      render

      expect(rendered).to have_content("No active lead providers for #{contract_period.year}")
    end
  end
end
