RSpec.describe "schools/register_ect_wizard/check_answers.html.erb" do
  let(:use_previous_ect_choices) { nil }
  let(:store) { build(:session_repository, working_pattern: 'Full time', use_previous_ect_choices:, training_programme: 'provider_led') }

  let(:wizard) do
    build(:register_ect_wizard, current_step: :check_answers, store:)
  end

  before do
    assign(:ect, wizard.ect)
    assign(:school, wizard.school)
    assign(:wizard, wizard)
  end

  it "sets the page title" do
    render
    expect(sanitize(view.content_for(:page_title))).to eql("Check your answers before submitting")
  end

  describe 'back link' do
    it 'links to the training programme step' do
      render
      expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: wizard.previous_step_path)
    end
  end

  it 'includes a continue button' do
    render
    expect(rendered).to have_button('Confirm details')
    expect(rendered).to have_selector("form[action='#{schools_register_ect_wizard_check_answers_path}']")
  end

  it 'includes a Programme details heading' do
    render
    expect(rendered).to have_content("Programme details")
  end

  describe 'programme details section' do
    before do
      allow(wizard.school).to receive(:last_programme_choices?).and_return(school_last_programme_choices)
    end

    context 'when the use previous ect choices is true' do
      let(:school_last_programme_choices) { true }

      context 'when choosing the same choices' do
        let(:use_previous_ect_choices) { true }

        it 'displays the "Choices used by your school previously" row' do
          render
          expect(rendered).to have_content('Choices used by your school previously')
          expect(rendered).to have_content('Yes, use the programme choices used by my school previously')
          expect(rendered).to have_link('Change', href: schools_register_ect_wizard_change_use_previous_ect_choices_path)
        end

        it 'hides change links for appropriate body, training programme and lead provider' do
          render
          expect(rendered).not_to have_link('Change', href: schools_register_ect_wizard_change_state_school_appropriate_body_path)
          expect(rendered).not_to have_link('Change', href: schools_register_ect_wizard_change_lead_provider_path)
        end

        context 'when ECT has provider-led programme' do
          before do
            allow(wizard.ect).to receive(:provider_led?).and_return(true)
          end

          it 'hides change link for lead provider' do
            render
            expect(rendered).not_to have_link('Change', href: schools_register_ect_wizard_change_training_programme_path)
          end
        end
      end

      context 'when use the school last programme choices is false' do
        let(:use_previous_ect_choices) { false }

        it 'displays the "Choices used by your school previously" row' do
          render
          expect(rendered).to have_content('Choices used by your school previously')
          expect(rendered).to have_content("No, don't use the programme choices used by my school previously")
          expect(rendered).to have_link('Change', href: schools_register_ect_wizard_change_use_previous_ect_choices_path)
        end

        it 'shows change links for appropriate body, training programme and lead provider' do
          render
          expect(rendered).to have_link('Change', href: schools_register_ect_wizard_change_state_school_appropriate_body_path)
          expect(rendered).to have_link('Change', href: schools_register_ect_wizard_change_lead_provider_path)
        end

        context 'when ECT has provider-led programme' do
          before do
            allow(wizard.ect).to receive(:provider_led?).and_return(true)
          end

          it 'hides change link for lead provider' do
            render
            expect(rendered).to have_link('Change', href: schools_register_ect_wizard_change_training_programme_path)
          end
        end
      end
    end

    context 'when school does not have last programme choices' do
      let(:school_last_programme_choices) { false }

      it 'does not display the "Choices used by your school previously" row' do
        render
        expect(rendered).not_to have_content('Choices used by your school previously')
      end

      it 'shows change links for appropriate body, training programme and lead provider' do
        render
        expect(rendered).to have_link('Change', href: schools_register_ect_wizard_change_state_school_appropriate_body_path)
        expect(rendered).to have_link('Change', href: schools_register_ect_wizard_change_lead_provider_path)
      end

      context 'when ECT has provider-led programme' do
        before do
          allow(wizard.ect).to receive(:provider_led?).and_return(true)
        end

        it 'hides change link for lead provider' do
          render
          expect(rendered).to have_link('Change', href: schools_register_ect_wizard_change_training_programme_path)
        end
      end
    end
  end
end
