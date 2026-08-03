RSpec.describe "admin/schools/add_partnership_wizard/select_lead_provider.html.erb" do
  let(:school) { FactoryBot.build(:school, create_contract_period: false) }
  let(:contract_period) { FactoryBot.create(:contract_period) }
  let(:store) do
    SessionRepository.new(session: {}, form_key: "add_partnership").tap do |repository|
      repository.contract_period_year = contract_period.year
    end
  end
  let(:wizard) do
    Admin::Schools::AddPartnershipWizard::Wizard.new(
      store:,
      school_urn: school.urn,
      current_step: :select_lead_provider
    )
  end

  before do
    assign(:school, school)
    assign(:wizard, wizard)
  end

  it "uses the fieldset legend as the page heading to avoid repeating the question for screen readers" do
    render

    expect(view.content_for(:page_header)).to be_blank
    expect(rendered).to have_css("legend h1", text: "Select the lead provider for #{contract_period.year}")
  end
end
