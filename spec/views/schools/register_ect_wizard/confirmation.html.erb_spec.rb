RSpec.describe "schools/register_ect_wizard/confirmation.html.erb" do
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, id: 1) }

  let(:ect) do
    double('ECT',
           full_name: 'John Doe',
           ect_at_school_period_id: 1,
           ect_at_school_period:)
  end

  before do
    assign(:ect, ect)
  end

  it "sets the page title" do
    render
    expect(sanitize(view.content_for(:page_title))).to eql("You have saved John Doe's details")
  end

  it "includes a link to view all ECTs" do
    render
    expect(rendered).to have_link('Back to your ECTs', href: schools_ects_home_path)
  end

  it "includes a link to assign a mentor" do
    render
    expect(rendered).to have_link('Assign a mentor', href: schools_register_mentor_wizard_start_path(ect_id: ect.ect_at_school_period_id))
  end
end
