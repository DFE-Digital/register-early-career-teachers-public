RSpec.describe "admin/finance/framework_agreements/bands/edit.html.erb" do
  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:framework_agreement) { FactoryBot.create(:framework_agreement, contract_period:) }
  let!(:band_a) { FactoryBot.create(:framework_agreement_band, framework_agreement:, capacity: 500) }
  let!(:band_b) { FactoryBot.create(:framework_agreement_band, framework_agreement:, capacity: 1500) }

  let(:index_path) { admin_contract_period_framework_agreement_bands_path(contract_period, framework_agreement) }
  let(:update_path) { admin_contract_period_framework_agreement_band_path(contract_period, framework_agreement, band_b) }

  before do
    assign(:framework_agreement, framework_agreement)
    assign(:band, band_b)
    assign(:breadcrumbs, {
      "Finance" => admin_finance_path,
      "Contract periods" => admin_contract_periods_path,
      contract_period.year.to_s => admin_contract_period_path(contract_period),
      framework_agreement.lead_provider_name => index_path
    })
  end

  it "renders the edit form" do
    render

    expect(view.content_for(:page_title)).to eq("Change capacity of Band B")
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Finance", href: admin_finance_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Contract periods", href: admin_contract_periods_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link(contract_period.year.to_s, href: admin_contract_period_path(contract_period))
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link(framework_agreement.lead_provider_name, href: index_path)

    expect(rendered).to have_selector("form[action='#{update_path}']")
    expect(rendered).to have_css("input[name='framework_agreement_band[capacity]'][value='#{band_b.capacity}']")
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
