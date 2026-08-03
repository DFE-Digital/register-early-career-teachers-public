RSpec.describe "admin/schools/add_partnership_wizard/select_contract_period.html.erb" do
  let(:school) { FactoryBot.build(:school, create_contract_period: false) }
  let(:store) { SessionRepository.new(session: {}, form_key: "add_partnership") }
  let(:wizard) do
    Admin::Schools::AddPartnershipWizard::Wizard.new(
      store:,
      school_urn: school.urn,
      current_step: :select_contract_period
    )
  end

  before do
    assign(:school, school)
    assign(:wizard, wizard)
  end

  it "uses the fieldset legend as the page heading to avoid repeating the question for screen readers" do
    render

    expect(view.content_for(:page_header)).to be_blank
    expect(rendered).to have_css("legend h1", text: "Select the contract period")
  end
end
