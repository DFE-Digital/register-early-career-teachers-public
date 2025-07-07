RSpec.describe "schools/register_mentor_wizard/start.html.erb" do
  let(:continue_path) { schools_register_mentor_wizard_find_mentor_path }
  let(:ect) { create(:ect_at_school_period, :active, :school_led) }
  let(:ect_name) { Teachers::Name.new(ect.teacher).full_name }

  before do
    assign(:ect, ect)
    assign(:ect_name, ect_name)
  end

  context "page title" do
    before { render }

    it { expect(sanitize(view.content_for(:page_title))).to eql("What you'll need to add a new mentor for #{ect_name}") }
  end

  context 'includes a back button' do
    context 'when the school has no mentors assignable to the ect' do
      let(:back_path) { schools_ects_home_path }

      before { render }

      it 'links back to the school ECTs listing' do
        expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: back_path)
      end
    end

    context 'when the school has mentors assignable to the ect' do
      let(:back_path) { new_schools_ect_mentorship_path(ect) }

      before do
        create(:mentor_at_school_period, :active, school: ect.school)
        render
      end

      it 'links back to the page to choose a mentor' do
        expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: back_path)
      end
    end
  end

  it 'includes a continue button that links to the find mentor page' do
    render

    expect(rendered).to have_link('Continue', href: continue_path)
  end

  context 'when the ect has chosen a provider led training programme' do
    let(:ect) { build(:ect_at_school_period, :provider_led) }

    it 'informs the user about the mentor training programme requirements' do
      render

      expect(rendered).to have_text('You may also need to tell us about the mentor’s training programme.')
    end
  end

  context 'when the ect has chosen a school led training programme' do
    let(:ect) { build(:ect_at_school_period, :school_led) }

    it 'does not inform the user about the mentor training programme requirements' do
      render

      expect(rendered).not_to have_text('You may also need to tell us about the mentor’s training programme.')
    end
  end
end
