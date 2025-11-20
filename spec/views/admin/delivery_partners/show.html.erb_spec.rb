RSpec.describe "admin/delivery_partners/show.html.erb" do
  let(:delivery_partner) { FactoryBot.create(:delivery_partner, name: "Test Delivery Partner") }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }
  let(:partnership) do
    FactoryBot.create(
      :lead_provider_delivery_partnership,
      delivery_partner:,
      active_lead_provider:
    )
  end

  before do
    assign(:delivery_partner, delivery_partner)
    assign(:page, "2")
    assign(:q, "search term")
    assign(:contract_period_partnerships, [
      { contract_period: partnership.contract_period, partnerships: [partnership] }
    ])
  end

  it %(sets the page title to the delivery partner name) do
    render

    expect(view.content_for(:page_title)).to eql("Test Delivery Partner")
  end

  it %(renders the link to change the delivery partner name) do
    render

    expect(rendered).to have_link("Change delivery partner name", href: edit_admin_delivery_partner_path(delivery_partner))
  end

  it "includes backlink with preserved page and query parameters" do
    render

    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Back", href: admin_delivery_partners_path(page: 2, q: "search term"))
  end

  it "renders the Lead provider partners table caption" do
    render

    expect(rendered).to have_css("table caption", text: "Lead provider partners")
  end

  it "renders a table with lead provider partnerships" do
    render

    expect(rendered).to have_css("table.govuk-table")
    expect(rendered).to have_css("th", text: "Year")
    expect(rendered).to have_css("th", text: "Lead provider")
    expect(rendered).to have_css("th", text: "Action")
    expect(rendered).to have_css("tbody tr", count: 1)
  end

  it "displays partnership details in the table" do
    render

    expect(rendered).to have_css("td", text: partnership.contract_period.year.to_s)
    expect(rendered).to have_css("td", text: partnership.lead_provider.name)
  end

  it "displays one change link per year group" do
    render

    expected_href = new_admin_delivery_partner_delivery_partnership_path(
      delivery_partner,
      partnership.contract_period.year,
      page: 2,
      q: "search term"
    )
    expect(rendered).to have_link("Change", href: expected_href)
  end

  context "when there are multiple partnerships for different years" do
    let(:old_active_lead_provider) { FactoryBot.create(:active_lead_provider) }
    let(:new_active_lead_provider) { FactoryBot.create(:active_lead_provider) }
    let(:old_partnership) do
      FactoryBot.create(
        :lead_provider_delivery_partnership,
        delivery_partner:,
        active_lead_provider: old_active_lead_provider
      )
    end
    let(:new_partnership) do
      FactoryBot.create(
        :lead_provider_delivery_partnership,
        delivery_partner:,
        active_lead_provider: new_active_lead_provider
      )
    end

    before do
      # Ensure different years for ordering test
      old_contract_period = FactoryBot.create(:contract_period, year: 2021)
      new_contract_period = FactoryBot.create(:contract_period, year: 2023)
      old_active_lead_provider.update!(contract_period: old_contract_period)
      new_active_lead_provider.update!(contract_period: new_contract_period)

      assign(:contract_period_partnerships, [
        { contract_period: new_contract_period, partnerships: [new_partnership] },
        { contract_period: old_contract_period, partnerships: [old_partnership] }
      ])
    end

    it "displays multiple partnerships" do
      render

      expect(rendered).to have_css("tbody tr", count: 2)
      expect(rendered).to have_css("td", text: "2021")
      expect(rendered).to have_css("td", text: "2023")
    end
  end

  context "when there are multiple partnerships for the same year" do
    let(:contract_period) { FactoryBot.create(:contract_period, year: 2025) }
    let(:lead_provider_1) { FactoryBot.create(:lead_provider, name: "Lead Provider 1") }
    let(:lead_provider_2) { FactoryBot.create(:lead_provider, name: "Lead Provider 2") }
    let(:active_lead_provider_1) { FactoryBot.create(:active_lead_provider, lead_provider: lead_provider_1, contract_period:) }
    let(:active_lead_provider_2) { FactoryBot.create(:active_lead_provider, lead_provider: lead_provider_2, contract_period:) }

    let(:partnership_1) do
      FactoryBot.create(
        :lead_provider_delivery_partnership,
        delivery_partner:,
        active_lead_provider: active_lead_provider_1
      )
    end
    let(:partnership_2) do
      FactoryBot.create(
        :lead_provider_delivery_partnership,
        delivery_partner:,
        active_lead_provider: active_lead_provider_2
      )
    end

    before do
      assign(:contract_period_partnerships, [
        { contract_period:, partnerships: [partnership_1, partnership_2] }
      ])
    end

    it "groups partnerships by year and displays lead providers in the same row" do
      render

      # Should have only one row for the year
      expect(rendered).to have_css("tbody tr", count: 1)
      expect(rendered).to have_css("td", text: "2025")

      # Should display both lead provider names in the same cell, separated by comma
      expect(rendered).to have_css("td", text: /Lead Provider 1.*Lead Provider 2/m)
    end

    it "displays one change link per year group" do
      render

      expect(rendered).to have_css(
        "table.govuk-table a",
        text: "Change",
        count: 1
      )
    end
  end

  context "when there are no contract periods with available lead providers" do
    before do
      assign(:contract_period_partnerships, [])
    end

    it "shows empty state message" do
      render

      expect(rendered).to have_css("p", text: "No contract periods with available lead providers found for this delivery partner.")
      expect(rendered).not_to have_css("table.govuk-table")
    end
  end

  context "when page parameters are nil" do
    before do
      assign(:page, nil)
      assign(:q, nil)
    end

    it "still renders backlink without parameters" do
      render

      expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Back", href: admin_delivery_partners_path)
    end
  end
end
