RSpec.describe "admin/finance/active_lead_providers/bands/edit.html.erb" do
  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:) }
  let!(:band_a) { FactoryBot.create(:active_lead_provider_band, active_lead_provider:, capacity: 500) }
  let!(:band_b) { FactoryBot.create(:active_lead_provider_band, active_lead_provider:, capacity: 1500) }

  let(:index_path) { admin_contract_period_active_lead_provider_bands_path(contract_period, active_lead_provider) }
  let(:update_path) { admin_contract_period_active_lead_provider_band_path(contract_period, active_lead_provider, band_b) }

  before do
    assign(:active_lead_provider, active_lead_provider)
    assign(:band, band_b)
    assign(:breadcrumbs, {
      "Finance" => admin_finance_path,
      "Contract periods" => admin_contract_periods_path,
      contract_period.year.to_s => admin_contract_period_path(contract_period),
      active_lead_provider.lead_provider_name => index_path
    })
  end

  it "renders the edit form" do
    render

    expect(view.content_for(:page_title)).to eq("Change capacity of Band B")
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Finance", href: admin_finance_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Contract periods", href: admin_contract_periods_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link(contract_period.year.to_s, href: admin_contract_period_path(contract_period))
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link(active_lead_provider.lead_provider_name, href: index_path)

    expect(rendered).to have_selector("form[action='#{update_path}']")
    expect(rendered).to have_css("input[name='active_lead_provider_band[capacity]'][value='#{band_b.capacity}']")
    expect(rendered).to have_button("Save")
  end

  context "when the form is invalid" do
    before do
      band_b.capacity = "bananas"
      band_b.valid?
    end

    it "prefixes the page title with 'Error:' and renders an error summary" do
      render

      expect(view.content_for(:page_title)).to start_with("Error:")
      expect(view.content_for(:error_summary)).to have_css(".govuk-error-summary")
    end
  end
end
