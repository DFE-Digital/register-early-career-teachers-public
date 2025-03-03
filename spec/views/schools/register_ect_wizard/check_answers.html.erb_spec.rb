RSpec.describe "schools/register_ect_wizard/check_answers.html.erb" do
  let(:ect) do
    double('ECT',
           full_name: 'John Doe',
           trn: '123456',
           email: 'foo@bar.com',
           govuk_date_of_birth: '12 January 1931',
           start_date: 'September 2022',
           programme_type: 'school_led',
           appropriate_body_type: 'teaching_school_hub',
           appropriate_body: double(name: 'Teaching Regulation Agency'),
           lead_provider: double(name: 'Acme Lead Provider'),
           formatted_working_pattern: 'Full time',
           provider_led?: false)
  end

  let(:wizard) do
    FactoryBot.build(:register_ect_wizard, current_step: :check_answers, store: {})
  end

  before do
    allow(wizard.ect).to receive(:provider_led?).and_return(false)
    assign(:ect, ect)
    assign(:wizard, wizard)
    render
  end

  it "sets the page title" do
    expect(sanitize(view.content_for(:page_title))).to eql("Check your answers before submitting")
  end

  describe 'back link' do
    context 'when the registration is school-led' do
      it 'links to the programme type step' do
        expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: schools_register_ect_wizard_programme_type_path)
      end
    end

    context 'when the registration is provider-led' do
      before do
        allow(wizard.ect).to receive(:provider_led?).and_return(true)
        render
      end

      it 'links to the lead provider step' do
        expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: schools_register_ect_wizard_lead_provider_path)
      end
    end
  end

  it 'includes a continue button' do
    expect(rendered).to have_button('Confirm details')
    expect(rendered).to have_selector("form[action='#{schools_register_ect_wizard_check_answers_path}']")
  end
end
