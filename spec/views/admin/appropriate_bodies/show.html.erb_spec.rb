RSpec.describe 'admin/appropriate_bodies/show.html.erb' do
  let(:current_ect_count) { 5 }
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  before do
    assign(:appropriate_body, appropriate_body)
    assign(:current_ect_count, current_ect_count)
    render
  end

  it 'sets the main heading and page title to the appropriate body name' do
    expect(view.content_for(:page_title)).to start_with(appropriate_body.name)
    expect(view.content_for(:page_header)).to have_css('h1', text: appropriate_body.name)
  end

  it 'displays a count of current ECTs' do
    expect(rendered).to have_css('.govuk-summary-list__value', text: current_ect_count)
  end

  it 'links to appropriate body timeline' do
    expect(rendered).to have_link('View activity', href: admin_appropriate_body_timeline_path(appropriate_body))
  end

  it "displays a link to the appropriate body's ECTs" do
    expect(rendered).to have_link('View current ECTs', href: admin_appropriate_body_current_ects_path(appropriate_body))
  end
end
