RSpec.describe "schools/register_mentor_wizard/start.html.erb" do
  let(:back_path) { schools_ects_home_path }
  let(:continue_path) { schools_register_mentor_wizard_find_mentor_path }
  let(:ect) { FactoryBot.build(:ect_at_school_period, :provider_led) }
  let(:ect_name) { 'James Lorie' }
  let(:title) {}

  before do
    assign(:ect, ect)
    assign(:ect_name, ect_name)
  end

  context "page title" do
    before { render }

    it { expect(sanitize(view.content_for(:page_title))).to eql("What you'll need to add a new mentor for #{ect_name}") }
  end

  it 'includes a back button that links to the school home page' do
    render

    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: back_path)
  end

  it 'includes a continue button that links to the find mentor page' do
    render

    expect(rendered).to have_link('Continue', href: continue_path)
  end

  context 'when the ect has chosen a provider led programme type' do
    let(:ect) { FactoryBot.build(:ect_at_school_period, :provider_led) }

    it 'informs the user about the mentor programme type requirements' do
      render

      expect(rendered).to have_text('You may also need to tell us about the mentor’s training programme.')
    end
  end

  context 'when the ect has chosen a school led programme type' do
    let(:ect) { FactoryBot.build(:ect_at_school_period, :school_led) }

    it 'does not inform the user about the mentor programme type requirements' do
      render

      expect(rendered).not_to have_text('You may also need to tell us about the mentor’s training programme.')
    end
  end
end
