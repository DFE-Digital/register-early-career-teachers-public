RSpec.describe "schools/register_ect_wizard/cannot_register_ect_yet" do
  let(:formatted_year) { '2024 to 2025' }
  let(:ect) { double('ECT', full_name: 'John Doe', start_date: '15 May 2025') }

  before do
    create(:contract_period, year: 2024, enabled: true)
    assign(:ect, ect)
    render
  end

  it "sets the page title" do
    expect(sanitize(view.content_for(:page_title))).to eql('You cannot register John Doe yet')
  end

  it "displays the cannot register ECT message" do
    expect(rendered).to have_content("Registration for the #{formatted_year} academic year is not open")
    expect(rendered).to have_content("We'll email you to let you know when registration will open. This is usually in June.")
  end

  it "includes a link back to ECTs" do
    expect(rendered).to have_link("Back to ECTs", href: schools_ects_home_path)
  end
end
