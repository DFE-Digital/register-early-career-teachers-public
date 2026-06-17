RSpec.describe "admin/finance/active_lead_providers/lead_provider_delivery_partnerships/index.html.erb" do
  let(:contract_period) do
    FactoryBot.create(:contract_period, year: 2099, started_on: Date.new(2099, 6, 1), finished_on: Date.new(2100, 5, 31))
  end
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:, lead_provider:) }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }
  let(:partnerships) { [lead_provider_delivery_partnership] }
  let(:pagy) { Pagy.new(count: partnerships.count, limit: 10, page: 1) }

  before do
    assign(:active_lead_provider, active_lead_provider)
    assign(:lead_provider_delivery_partnerships, partnerships)
    assign(:pagy, pagy)
    assign(:breadcrumbs, {
      "Finance" => admin_finance_path,
      "Contract periods" => admin_contract_periods_path,
      contract_period.year.to_s => admin_contract_period_path(contract_period),
      lead_provider.name => admin_contract_period_active_lead_providers_path(contract_period),
    })
  end

  it "renders the title, breadcrumbs, delivery partners table, remove buttons, and add button" do
    render

    expect(view.content_for(:page_title)).to eq("#{lead_provider.name} delivery partnerships for 2099")
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Finance", href: admin_finance_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Contract periods", href: admin_contract_periods_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link(contract_period.year.to_s, href: admin_contract_period_path(contract_period))
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link(lead_provider.name, href: admin_contract_period_active_lead_providers_path(contract_period))

    expect(rendered).to have_link(delivery_partner.name, href: admin_delivery_partner_path(delivery_partner))
    expect(rendered).to have_link("Remove", href: delete_admin_contract_period_active_lead_provider_lead_provider_delivery_partnership_path(contract_period, active_lead_provider, lead_provider_delivery_partnership))
    expect(rendered).to have_link("Add delivery partner", href: new_admin_contract_period_active_lead_provider_lead_provider_delivery_partnership_path(contract_period, active_lead_provider))
    expect(rendered).not_to have_selector("a[aria-disabled='true']", text: "Add delivery partner")
  end

  context "when the contract period has already started" do
    let(:contract_period) do
      FactoryBot.create(:contract_period, year: 2020, started_on: Date.new(2020, 6, 1), finished_on: Date.new(2021, 5, 31))
    end

    it "hides remove buttons and renders the add button in a disabled state" do
      render

      expect(rendered).not_to have_link("Remove")
      expect(rendered).to have_selector("a[disabled], a[aria-disabled='true']", text: "Add delivery partner")
    end
  end

  context "when there are no delivery partners" do
    let(:partnerships) { [] }

    it "displays a message informing me there are no delivery partners" do
      render

      expect(rendered).to have_content("No delivery partners found")
      expect(rendered).not_to have_css(".govuk-table")
    end
  end
end
