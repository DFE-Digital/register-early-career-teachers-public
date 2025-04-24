RSpec.describe "schools/register_ect_wizard/check_answers.html.erb" do
  let(:use_previous_ect_choices) { nil }
  let(:store) { FactoryBot.build(:session_repository, working_pattern: 'Full time', use_previous_ect_choices:) }

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

  it 'includes a Programme details heading' do
    expect(rendered).to have_content("Programme details")
  end

  describe 'programme details section' do
    before do
      allow(wizard.school).to receive(:programme_choices?).and_return(programme_choices)
      render
    end

    context 'when school has programme choices' do
      let(:programme_choices) { true }

      context 'when choosing the same choices' do
        let(:use_previous_ect_choices) { true }

        it 'displays the "Choices used by your school previously" row' do
          expect(rendered).to have_content('Choices used by your school previously')
          expect(rendered).to have_content('Yes, use the programme choices used by my school previously')
          expect(rendered).to have_link('Change', href: schools_register_ect_wizard_change_use_previous_ect_choices_path)
        end
      end

      context 'when choosing different choices' do
        let(:use_previous_ect_choices) { false }

        it 'displays the "Choices used by your school previously" row' do
          expect(rendered).to have_content('Choices used by your school previously')
          expect(rendered).to have_content("No, don't use the programme choices used by my school previously")
          expect(rendered).to have_link('Change', href: schools_register_ect_wizard_change_use_previous_ect_choices_path)
        end
      end
    end

    context 'when school does not have programme choices' do
      let(:programme_choices) { false }

      it 'does not display the "Choices used by your school previously" row' do
        expect(rendered).not_to have_content('Choices used by your school previously')
      end
    end
  end
end
