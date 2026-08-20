RSpec.describe "admin/finance/framework_agreements/bands/new.html.erb" do
  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:framework_agreement) { FactoryBot.create(:framework_agreement, contract_period:) }
  let(:band_a) { FactoryBot.create(:framework_agreement_band, framework_agreement:, capacity: 500) }
  let(:band_b) { FactoryBot.create(:framework_agreement_band, framework_agreement:, capacity: 1500) }
  let(:band_c) { framework_agreement.bands.new }

  let(:index_path) { admin_contract_period_framework_agreement_bands_path(contract_period, framework_agreement) }

  before do
    assign(:framework_agreement, framework_agreement)
    assign(:band, band_c)
    assign(:breadcrumbs, {
      "Finance" => admin_finance_path,
      "Contract periods" => admin_contract_periods_path,
      contract_period.year.to_s => admin_contract_period_path(contract_period),
      framework_agreement.lead_provider_name => index_path
    })
  end

  it "renders the new form" do
    render

    expect(view.content_for(:page_title)).to eq("Add band to #{framework_agreement.lead_provider_name}")
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Finance", href: admin_finance_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Contract periods", href: admin_contract_periods_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link(contract_period.year.to_s, href: admin_contract_period_path(contract_period))
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link(framework_agreement.lead_provider_name, href: index_path)

    expect(rendered).to have_selector("form[action='#{index_path}']")
    expect(rendered).to have_css("input[name='framework_agreement_band[capacity]']")
    expect(rendered).to have_button("Add new band")
  end

  context "when the form is invalid" do
    let(:band_c) { framework_agreement.bands.new.tap(&:valid?) }

    it "prefixes the page title with 'Error:' and renders an error summary" do
      render

      expect(view.content_for(:page_title)).to start_with("Error:")
      expect(view.content_for(:error_summary)).to have_css(".govuk-error-summary")
    end
  end
end
