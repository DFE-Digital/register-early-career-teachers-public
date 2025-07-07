RSpec.describe "schools/register_mentor_wizard/confirmation.md.erb" do
  let(:already_active_at_school) { false }

  let(:lead_provider) { create(:lead_provider, name: 'FraggleRock') }

  let(:teacher) { create(:teacher, trn: '1234568') }

  let(:ect) { create(:ect_at_school_period, :active, teacher:, lead_provider:) }

  let(:store) do
    double(
      trn: '0000007',
      trs_first_name: "John",
      trs_last_name: "Wayne",
      change_name: 'no',
      corrected_name: nil,
      already_active_at_school:,
      eligible_for_mentor_funding?: true
    )
  end

  let(:wizard) do
    build(:register_mentor_wizard, current_step: :confirmation, ect_id: ect.id, store:)
  end

  let(:mentor) { wizard.mentor }

  before do
    assign(:wizard, wizard)
    assign(:mentor, mentor)
    assign(:ect_name, "Michale Dixon")

    render
  end

  describe 'page title' do
    let(:title) { sanitize(view.content_for(:page_title)) }

    it { expect(title).to eql("You've assigned #{mentor.full_name} as a mentor") }
  end

  it 'includes no back link' do
    expect(view.content_for(:backlink_or_breadcrumb)).to be_blank
  end

  it 'links to the school home page' do
    expect(rendered).to have_link('Back to ECTs', href: schools_ects_home_path)
  end

  describe 'mentor funding' do
    context 'when eligible' do
      context 'when the ect is provider_led' do
        it { expect(rendered).to have_content("We’ll pass on their details to FraggleRock") }
      end

      context 'when the ect is not provider_led' do
        let(:ect) { create(:ect_at_school_period, :active, :school_led, teacher:) }

        it { expect(rendered).not_to have_content("We’ll pass on their details to FraggleRock") }
      end
    end

    context 'when ineligible' do
      before do
        create(:teacher, :ineligible_for_mentor_funding, trn: '0000007')
        render
      end

      context 'when the ect is provider_led' do
        it { expect(rendered).to have_content('They cannot do mentor training according to our records.') }
      end

      context 'when the ect is not provider_led' do
        let(:ect) { create(:ect_at_school_period, :active, :school_led, teacher:) }

        it { expect(rendered).not_to have_content('They cannot do mentor training according to our records.') }
      end
    end
  end

  context "when the mentor is already active at the school" do
    let(:already_active_at_school) { true }

    it 'does not mention an email sent to the mentor' do
      expect(rendered).not_to have_content('What happens next')
      expect(rendered).not_to have_content("We'll email #{mentor.full_name} to confirm you have registered them.")
    end
  end

  context "when the mentor is not active at the school" do
    let(:already_active_at_school) { false }

    it 'mentions an email sent to the mentor' do
      expect(rendered).to have_content('What happens next')
      expect(rendered).to have_content("We’ll email #{mentor.full_name} to confirm you have registered them.")
    end
  end
end
