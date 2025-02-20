RSpec.describe "schools/register_mentor_wizard/confirmation.md.erb" do
  let(:already_active_at_school) { false }
  let(:ect_name) { "Michale Dixon" }
  let(:your_ects_path) { schools_ects_home_path }
  let(:mentor) { wizard.mentor }
  let(:store) { double(trs_first_name: "John", trs_last_name: "Wayne", corrected_name: nil, already_active_at_school:) }
  let(:wizard) { FactoryBot.build(:register_mentor_wizard, current_step: :confirmation, store:) }

  before do
    assign(:wizard, wizard)
    assign(:ect_name, ect_name)
    assign(:mentor, mentor)

    render
  end

  context "page title" do
    it { expect(sanitize(view.content_for(:page_title))).to eql("You've assigned #{mentor.full_name} as a mentor") }
  end

  it 'includes no back button' do
    expect(view.content_for(:backlink_or_breadcrumb)).to be_blank
  end

  it 'includes a button that links to the school home page' do
    expect(rendered).to have_link('Back to ECTs', href: your_ects_path)
  end

  context "when the mentor is already active at the school" do
    let(:already_active_at_school) { true }

    it 'does not mention an email sent to the mentor' do
      expect(rendered).not_to include('What happens next')
      expect(rendered).not_to include(ERB::Util.html_escape("We'll email #{mentor.full_name} to confirm you have registered them."))
    end
  end

  context "when the mentor is not active at the school" do
    it 'mentions an email sent to the mentor' do
      expect(rendered).to include('What happens next')
      expect(rendered).to include(ERB::Util.html_escape("We'll email #{mentor.full_name} to confirm you have registered them."))
    end
  end
end
