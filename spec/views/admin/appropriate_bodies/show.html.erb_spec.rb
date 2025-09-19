RSpec.describe 'admin/appropriate_bodies/show.html.erb' do
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  before do
    assign(:appropriate_body, appropriate_body)
    render
  end

  it 'sets the main heading and page title to the appropriate body name' do
    expect(view.content_for(:page_title)).to start_with(appropriate_body.name)
    expect(view.content_for(:page_header)).to have_css('h1', text: appropriate_body.name)
  end

  it 'displays the DfE Sign In organisation ID' do
    expect(rendered).to have_css('.govuk-summary-list__value', text: appropriate_body.dfe_sign_in_organisation_id)
  end

  it 'displays counts of current ECTs and bulk uploads' do
    expect(rendered).to have_css('.govuk-summary-list__value', exact_text: '0', count: 2)
  end

  it 'links to appropriate body timeline', skip: 'disabled for manual testing' do
    expect(rendered).to have_link('Timeline of events', href: admin_appropriate_body_timeline_path(appropriate_body))
  end
end
