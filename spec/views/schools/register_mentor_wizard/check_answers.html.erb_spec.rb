RSpec.describe "schools/register_mentor_wizard/check_answers.html.erb" do
  let(:lead_provider) { create(:lead_provider, name: 'FraggleRock') }

  let(:teacher) do
    create(:teacher, trn: '1234568')
  end

  let(:ect) do
    create(:ect_at_school_period, :active, teacher:, lead_provider:)
  end

  let(:store) do
    build(:session_repository,
          trn: "1234567",
          trs_first_name: "John",
          trs_last_name: "Wayne",
          change_name: 'yes',
          corrected_name: "Jim Wayne",
          email: "john.wayne@example.com")
  end

  let(:wizard) do
    build(:register_mentor_wizard, current_step: :check_answers, ect_id: ect.id, store:)
  end

  let(:mentor) { wizard.mentor }

  before do
    assign(:wizard, wizard)
    assign(:mentor, mentor)
    assign(:ect_name, "Michael Dixon")
  end

  describe 'page title' do
    let(:title) { sanitize(view.content_for(:page_title)) }

    before { render }

    it { expect(title).to eql("Check your answers and confirm mentor details") }
  end

  describe 'back link' do
    let(:backlink) { view.content_for(:backlink_or_breadcrumb) }

    context 'without exemption' do
      before { render }

      it { expect(backlink).to have_link('Back', href: schools_register_mentor_wizard_review_mentor_eligibility_path) }
    end

    context 'with legacy exemption' do
      before do
        create(:teacher, :early_roll_out_mentor, trn: mentor.trn)
        render
      end

      it { expect(backlink).to have_link('Back', href: schools_register_mentor_wizard_email_address_path) }
    end

    context 'with existing training exemption' do
      before do
        create(:teacher,
               trn: mentor.trn,
               mentor_became_ineligible_for_funding_on: Time.zone.today,
               mentor_became_ineligible_for_funding_reason: 'completed_declaration_received')

        render
      end

      it { expect(backlink).to have_link('Back', href: schools_register_mentor_wizard_email_address_path) }
    end
  end

  describe 'summary' do
    context 'with school led ect' do
      let(:ect) do
        create(:ect_at_school_period, :active, :school_led, teacher:)
      end

      it 'hides lead provider' do
        expect(rendered).not_to have_element(:dt, text: "Lead provider")
      end
    end

    context 'without exemption' do
      before { render }

      it 'displays TRN, Name and Email address, lead provider' do
        expect(rendered).to have_element(:dt, text: "Teacher reference number (TRN)")
        expect(rendered).to have_element(:dd, text: "1234567")
        expect(rendered).to have_element(:dt, text: "Name")
        expect(rendered).to have_element(:dd, text: "Jim Wayne")
        expect(rendered).to have_element(:dt, text: "Email address")
        expect(rendered).to have_element(:dd, text: "john.wayne@example.com")
        expect(rendered).to have_element(:dt, text: "Lead provider")
        expect(rendered).to have_element(:dd, text: "FraggleRock")
      end
    end

    context 'with legacy exemption' do
      before do
        create(:teacher, :early_roll_out_mentor, trn: mentor.trn)
        render
      end

      it 'hides lead provider' do
        expect(rendered).not_to have_element(:dt, text: "Lead provider")
        expect(rendered).not_to have_element(:dd, text: "FraggleRock")
      end
    end

    context 'with existing training exemption' do
      before do
        create(:teacher,
               trn: mentor.trn,
               mentor_became_ineligible_for_funding_on: Time.zone.today,
               mentor_became_ineligible_for_funding_reason: 'completed_declaration_received')

        render
      end

      it 'hides lead provider' do
        expect(rendered).not_to have_element(:dt, text: "Lead provider")
        expect(rendered).not_to have_element(:dd, text: "FraggleRock")
      end
    end
  end

  it 'includes an inset with the names of the mentor and ECT associated' do
    render
    expect(rendered).to have_selector(".govuk-inset-text", text: 'Jim Wayne will mentor Michael Dixon', visible: :visible)
  end

  it 'includes a Confirm details button that posts to the check answers page' do
    render
    expect(rendered).to have_button('Confirm details')
    expect(rendered).to have_selector("form[action='#{schools_register_mentor_wizard_check_answers_path}']")
  end

  it 'has change links' do
    render
    expect(rendered).to have_link('Change', href: schools_register_mentor_wizard_change_mentor_details_path)
    expect(rendered).to have_link('Change', href: schools_register_mentor_wizard_change_email_address_path)
  end
end
