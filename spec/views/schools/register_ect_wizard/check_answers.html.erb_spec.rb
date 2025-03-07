RSpec.describe "schools/register_ect_wizard/check_answers.html.erb" do
  let(:store) { FactoryBot.build(:session_repository, working_pattern: 'Full time') }

  let(:wizard) do
    FactoryBot.build(:register_ect_wizard, current_step: :check_answers, store:)
  end

  before do
    assign(:ect, wizard.ect)
    assign(:school, wizard.school)
    assign(:wizard, wizard)

    render
  end

  it "sets the page title" do
    expect(sanitize(view.content_for(:page_title))).to eql("Check your answers before submitting")
  end

  describe 'back link' do
    it 'links to the programme type step' do
      expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: wizard.previous_step_path)
    end
  end

  it 'includes a continue button' do
    expect(rendered).to have_button('Confirm details')
    expect(rendered).to have_selector("form[action='#{schools_register_ect_wizard_check_answers_path}']")
  end
end
