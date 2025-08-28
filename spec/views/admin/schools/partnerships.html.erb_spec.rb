RSpec.describe 'admin/schools/partnerships.html.erb', type: :view do
  let(:school) { FactoryBot.create(:school) }

  before do
    assign(:school, school)
    assign(:breadcrumbs, { "Schools" => "/admin/schools", school.name => nil })
    assign(:navigation_items, [
      { text: "Overview", href: overview_admin_school_path(school.urn), current: false },
      { text: "Teachers", href: teachers_admin_school_path(school.urn), current: false },
      { text: "Partnerships", href: partnerships_admin_school_path(school.urn), current: true }
    ])
    allow(view).to receive_messages(params: { urn: school.urn }, request: double(fullpath: "/admin/schools/#{school.urn}/partnerships"))
  end

  it 'sets up breadcrumbs in page data' do
    render

    expect(view.content_for(:backlink_or_breadcrumb)).to include('govuk-breadcrumbs')
    expect(view.content_for(:backlink_or_breadcrumb)).to include('Schools')
    expect(view.content_for(:backlink_or_breadcrumb)).to include(school.name)
  end

  it 'displays school URN in caption and name as H1' do
    render

    expect(view.content_for(:page_caption)).to include("URN: #{school.urn}")
    expect(view.content_for(:page_header)).to include(school.name)
  end

  it 'displays secondary navigation' do
    render

    expect(rendered).to have_css('nav.x-govuk-secondary-navigation')
    expect(rendered).to have_css('ul.x-govuk-secondary-navigation__list')
    expect(rendered).to have_css('a', text: 'Overview')
    expect(rendered).to have_css('a', text: 'Teachers')
    expect(rendered).to have_css('a', text: 'Partnerships')
  end

  it 'displays placeholder content' do
    render

    expect(rendered).to have_css('p', text: 'Partnership information will be available here in the future.')
  end

  it 'marks partnerships as current in navigation' do
    render

    expect(rendered).to have_css('.x-govuk-secondary-navigation__list-item--current a', text: 'Partnerships')
    expect(rendered).to have_css('a[aria-current="page"]', text: 'Partnerships')
  end
end
