RSpec.describe "schools/register_ect_wizard/check_answers.html.erb" do
  let(:use_previous_ect_choices) { nil }
  let(:store) { FactoryBot.build(:session_repository, working_pattern: 'Full time', use_previous_ect_choices:, training_programme: 'provider_led') }

  let(:wizard) do
    FactoryBot.build(:register_ect_wizard, current_step: :check_answers, store:)
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

        it 'hides change links for appropriate body, training programme and lead provider' do
          render
          expect(rendered).not_to have_link('Change', href: schools_register_ect_wizard_change_state_school_appropriate_body_path)
          expect(rendered).not_to have_link('Change', href: schools_register_ect_wizard_change_lead_provider_path)
        end

        context 'when ECT has provider-led programme' do
          before do
            allow(wizard.ect).to receive(:provider_led?).and_return(true)
            allow(wizard.ect).to receive(:lead_provider_has_confirmed_partnership_for_contract_period?).with(wizard.school).and_return(true)
            allow(wizard.ect).to receive_messages(lead_provider_name: "Confirmed LP", delivery_partner_name: "Confirmed DP")
          end

          it 'hides change link for lead provider' do
            render
            expect(rendered).not_to have_link('Change', href: schools_register_ect_wizard_change_training_programme_path)
          end

          it 'renders the delivery partner name from confirmed previous choices' do
            render

            expect(rendered).to have_css('.govuk-summary-list__key', text: 'Delivery partner')
            expect(rendered).to have_css('.govuk-summary-list__value', text: 'Confirmed DP')
          end
        end
      end

      context 'when use the school last programme choices is false' do
        let(:use_previous_ect_choices) { false }

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
          allow(wizard.ect).to receive(:lead_provider_has_confirmed_partnership_for_contract_period?)
            .with(wizard.school).and_return(true)
          allow(wizard.ect).to receive_messages(provider_led?: true, delivery_partner_name: "Should Not Show")
        end

        it 'hides change link for lead provider' do
          render
          expect(rendered).to have_link('Change', href: schools_register_ect_wizard_change_training_programme_path)
        end

        it 'does not render the delivery partner row' do
          render
          expect(rendered).not_to have_css('.govuk-summary-list__key', text: 'Delivery partner')
          expect(rendered).not_to have_css('.govuk-summary-list__value', text: 'Should Not Show')
        end
      end
    end
  end
end
