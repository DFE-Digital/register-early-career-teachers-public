RSpec.describe "admin/finance/active_lead_providers/lead_provider_delivery_partnerships/new.html.erb" do
  let(:contract_period) do
    FactoryBot.create(:contract_period, year: 2099, started_on: Date.new(2099, 6, 1), finished_on: Date.new(2100, 5, 31))
  end
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:, lead_provider:) }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
  let(:lead_provider_delivery_partnership) { LeadProviderDeliveryPartnership.new }

  let(:index_path) { admin_contract_period_active_lead_provider_lead_provider_delivery_partnerships_path(contract_period, active_lead_provider) }

  before do
    assign(:active_lead_provider, active_lead_provider)
    assign(:lead_provider_delivery_partnership, lead_provider_delivery_partnership)
    assign(:available_delivery_partners, [delivery_partner])
  end

  it "renders the new form with a delivery partner select and a back link" do
    render

    expect(view.content_for(:page_title)).to eq("Add delivery partner to #{lead_provider.name} for 2099")
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Back", href: index_path)

    expect(rendered).to have_selector("form[action='#{index_path}']")
    expect(rendered).to have_css("select[name='lead_provider_delivery_partnership[delivery_partner_id]'] option[value='#{delivery_partner.id}']", text: delivery_partner.name)
    expect(rendered).to have_button("Save")
  end

  context "when the form is invalid" do
    let(:lead_provider_delivery_partnership) { LeadProviderDeliveryPartnership.new.tap(&:valid?) }

    it "prefixes the page title with 'Error:' and renders an error summary" do
      render

      expect(view.content_for(:page_title)).to start_with("Error:")
      expect(view.content_for(:error_summary)).to have_css(".govuk-error-summary")
    end
  end
end
