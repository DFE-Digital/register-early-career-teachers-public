RSpec.describe 'admin/schools/overviews/show.html.erb', type: :view do
  let(:school) { FactoryBot.create(:school) }

  before do
    assign(:school, school)
    assign(:breadcrumbs, { "Schools" => "/admin/schools", school.name => nil })
    assign(:navigation_items, [
      { text: "Overview", href: admin_school_overview_path(school.urn), current: true },
      { text: "Teachers", href: admin_school_teachers_path(school.urn), current: false },
      { text: "Partnerships", href: admin_school_partnerships_path(school.urn), current: false }
    ])
    allow(view).to receive_messages(params: { urn: school.urn }, request: double(fullpath: "/admin/schools/#{school.urn}/overview"))
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

  it 'has an impersonation button' do
    render

    expect(rendered).to have_css('.govuk-button', text: "Sign in as #{school.name}")
  end

  it 'displays secondary navigation' do
    render

    expect(rendered).to have_css('nav.x-govuk-secondary-navigation')
    expect(rendered).to have_css('ul.x-govuk-secondary-navigation__list')
    expect(rendered).to have_css('a', text: 'Overview')
    expect(rendered).to have_css('a', text: 'Teachers')
    expect(rendered).to have_css('a', text: 'Partnerships')
  end

  it 'renders the overview component with school data' do
    render

    expect(rendered).to have_css('.govuk-summary-list')
    expect(rendered).to have_css('dt', text: 'Induction tutor')
    expect(rendered).to have_css('dt', text: 'Induction tutor email')
    expect(rendered).to have_css('dt', text: 'Local authority')
    expect(rendered).to have_css('dt', text: 'Address')
    expect(rendered).to have_css('a', text: 'Change')
  end

  it 'marks overview as current in navigation' do
    render

    expect(rendered).to have_css('.x-govuk-secondary-navigation__list-item--current a', text: 'Overview')
    expect(rendered).to have_css('a[aria-current="page"]', text: 'Overview')
  end
end
