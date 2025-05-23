RSpec.describe "schools/register_ect_wizard/not_found.html.erb" do
  before { render }

  it "sets the page title to 'We're unable to match the ECT with the details you provided'" do
    expect(sanitize(view.content_for(:page_title))).to eql("We're unable to match the ECT with the details you provided")
  end

  it 'includes no back link' do
    expect(view.content_for(:backlink_or_breadcrumb)).to be_blank
  end

  it 'includes a link to reviewing the teacher record' do
    expect(rendered).to have_link('reviewing their teacher record', href: "https://www.gov.uk/guidance/check-a-teachers-record")
  end

  it 'includes a link to the Find a lost TRN service' do
    expect(rendered).to have_link('Find a lost TRN service', href: "https://find-a-lost-trn.education.gov.uk/start")
  end

  it 'includes a try again button that links to the find ECT page' do
    expect(rendered).to have_link('Try again', href: schools_register_ect_wizard_find_ect_path)
  end
end
