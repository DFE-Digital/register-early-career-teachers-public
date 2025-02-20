RSpec.describe "schools/register_mentor_wizard/already_active_at_school.md.erb" do
  let(:assign_mentor_path) { wizard.current_step_path }
  let(:ect_name) { Faker::Name.name }
  let(:store) { double(trs_first_name: "John", trs_last_name: "Waters", corrected_name: "Jim Waters") }
  let(:wizard) { FactoryBot.build(:register_mentor_wizard, current_step: :already_active_at_school, store:) }
  let(:mentor) { wizard.mentor }

  before do
    assign(:wizard, wizard)
    assign(:mentor, mentor)
    assign(:ect_name, ect_name)
    render
  end

  context "page title" do
    it { expect(sanitize(view.content_for(:page_title))).to eql("This mentor has already been registered") }
  end

  it 'includes no back button' do
    expect(view.content_for(:backlink_or_breadcrumb)).to be_blank
  end

  it 'includes a button to assign the existing mentor to the ECT' do
    expect(rendered).to have_button("Assign #{mentor.full_name} to mentor #{ect_name}")
    expect(rendered).to have_selector("form[action='#{assign_mentor_path}']")
  end

  it "includes a link back to ECTs" do
    expect(rendered).to have_link("Back to ECTs", href: schools_ects_home_path)
  end
end
