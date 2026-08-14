RSpec.describe "admin/finance/framework_agreements/lead_provider_delivery_partnerships/delete.html.erb" do
  let(:contract_period) do
    FactoryBot.create(:contract_period, year: 2099, started_on: Date.new(2099, 6, 1), finished_on: Date.new(2100, 5, 31))
  end
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:framework_agreement) { FactoryBot.create(:framework_agreement, contract_period:, lead_provider:) }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, framework_agreement:, delivery_partner:) }

  let(:index_path) { admin_contract_period_framework_agreement_lead_provider_delivery_partnerships_path(contract_period, framework_agreement) }
  let(:destroy_path) { admin_contract_period_framework_agreement_lead_provider_delivery_partnership_path(contract_period, framework_agreement, lead_provider_delivery_partnership) }

  before do
    assign(:framework_agreement, framework_agreement)
    assign(:lead_provider_delivery_partnership, lead_provider_delivery_partnership)
  end

  it "renders the delete confirmation with a back link, warning and remove button" do
    render

    expect(view.content_for(:page_title)).to eq("Remove #{delivery_partner.name} from 2099")
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Back", href: index_path)

    expect(rendered).to have_content("Are you sure you want to remove #{delivery_partner.name}?")
    expect(rendered).to have_selector("form[action='#{destroy_path}']")
    expect(rendered).to have_selector("input[name='_method'][value='delete']", visible: :all)
    expect(rendered).to have_button("Remove delivery partner")
    expect(rendered).to have_link("Cancel", href: index_path)
  end

  context "when the delivery partner has school partnerships" do
    before { allow(lead_provider_delivery_partnership).to receive(:school_partnerships).and_return(double(any?: true)) }

    it "explains it cannot be removed and hides the remove button" do
      render

      expect(rendered).to have_content("school partnerships and cannot be removed")
      expect(rendered).not_to have_button("Remove delivery partner")
      expect(rendered).to have_link("Return to delivery partnerships", href: index_path)
    end
  end
end
