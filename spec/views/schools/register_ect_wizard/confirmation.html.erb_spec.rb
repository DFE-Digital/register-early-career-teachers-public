RSpec.describe "schools/register_ect_wizard/confirmation.html.erb" do
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, id: 1) }
  let(:ect) { double('ECT', full_name: 'John Doe', ect_at_school_period_id: 1, ect_at_school_period:) }
  let(:title) { "You have saved #{ect.full_name}'s details" }
  let(:ects_link) { schools_ects_home_path }
  let(:assign_mentor_link) { schools_register_mentor_wizard_start_path(ect_id: ect.ect_at_school_period_id) }

  before do
    assign(:ect, ect)
  end

  it "sets the page title to 'You have saved John Doe's details" do
    render

    expect(sanitize(view.content_for(:page_title))).to eql(sanitize(title))
  end

  it "includes a link to view all ECTs" do
    render

    expect(rendered).to have_link('Back to your ECTs', href: ects_link)
  end

  it "includes a link to assign a mentor" do
    render

    expect(rendered).to have_link('Assign a mentor', href: assign_mentor_link)
  end
end
