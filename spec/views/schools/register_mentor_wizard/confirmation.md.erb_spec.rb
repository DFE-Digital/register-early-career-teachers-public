RSpec.describe "schools/register_mentor_wizard/confirmation.md.erb" do
  let(:already_active_at_school) { false }

  let(:lead_provider) { FactoryBot.create(:lead_provider, name: 'FraggleRock') }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:) }
  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
  let(:school_partnership) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:) }

  let(:teacher) { FactoryBot.create(:teacher, trn: '1234568') }

  let(:ect) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher:, school: school_partnership.school) }

  let(:store) do
    FactoryBot.build(:session_repository,
                     trn: '0000007',
                     trs_first_name: "John",
                     trs_last_name: "Wayne",
                     change_name: 'no',
                     corrected_name: nil,
                     already_active_at_school:,
                     eligible_for_mentor_funding?: true,
                     ect_id: ect.id)
  end

  let(:wizard) do
    FactoryBot.build(:register_mentor_wizard, current_step: :confirmation, ect_id: ect.id, store:)
  end

  let(:mentor) { wizard.mentor }

  describe 'page title' do
    let(:title) { sanitize(view.content_for(:page_title)) }

    it do
      assign(:wizard, wizard)
      assign(:mentor, mentor)
      assign(:ect_name, "Michale Dixon")

      render

      expect(title).to eql("You've assigned #{mentor.full_name} as a mentor")
    end
  end

  it 'includes no back link' do
    assign(:wizard, wizard)
    assign(:mentor, mentor)
    assign(:ect_name, "Michale Dixon")

    render

    expect(view.content_for(:backlink_or_breadcrumb)).to be_blank
  end

  it 'links to the school home page' do
    assign(:wizard, wizard)
    assign(:mentor, mentor)
    assign(:ect_name, "Michale Dixon")

    render

    expect(rendered).to have_link('Back to ECTs', href: schools_ects_home_path)
  end

  describe 'mentor funding' do
    context 'when eligible' do
      context 'when the ect is provider_led' do
        let!(:training_period) { FactoryBot.create(:training_period, :provider_led, :ongoing, ect_at_school_period: ect, school_partnership:) }

        it do
          assign(:wizard, wizard)
          assign(:mentor, mentor)
          assign(:ect_name, "Michale Dixon")

          render

          expect(rendered).to have_content("We’ll pass on their details to FraggleRock")
        end
      end

      context 'when the ect is not provider_led' do
        before { allow(ect).to receive(:provider_led_training_programme?).and_return(false) }

        it do
          assign(:wizard, wizard)
          assign(:mentor, mentor)
          assign(:ect_name, "Michale Dixon")

          render

          expect(rendered).not_to have_content("We’ll pass on their details to FraggleRock")
        end
      end
    end

    context 'when ineligible' do
      context 'when the ect is provider_led' do
        before do
          allow(wizard.ect).to receive(:provider_led_training_programme?).and_return(true)
          allow(mentor).to receive(:eligible_for_funding?).and_return(false)
        end

        it do
          assign(:wizard, wizard)
          assign(:mentor, mentor)
          assign(:ect_name, "Michale Dixon")

          render

          expect(rendered).to have_content('They cannot do mentor training according to our records.')
        end
      end

      context 'when the ect is not provider_led' do
        before { allow(ect).to receive(:provider_led_training_programme?).and_return(false) }

        it do
          assign(:wizard, wizard)
          assign(:mentor, mentor)
          assign(:ect_name, "Michale Dixon")

          render

          expect(rendered).not_to have_content('They cannot do mentor training according to our records.')
        end
      end
    end
  end

  context "when the mentor is already active at the school" do
    let(:already_active_at_school) { true }

    it 'does not mention an email sent to the mentor' do
      assign(:wizard, wizard)
      assign(:mentor, mentor)
      assign(:ect_name, "Michale Dixon")

      render

      expect(rendered).not_to have_content('What happens next')
      expect(rendered).not_to have_content("We'll email #{mentor.full_name} to confirm you have registered them.")
    end
  end

  context "when the mentor is not active at the school" do
    let(:already_active_at_school) { false }

    it 'mentions an email sent to the mentor' do
      assign(:wizard, wizard)
      assign(:mentor, mentor)
      assign(:ect_name, "Michale Dixon")

      render

      expect(rendered).to have_content('What happens next')
      expect(rendered).to have_content("We’ll email #{mentor.full_name} to confirm you have registered them.")
    end
  end
end
