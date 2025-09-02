RSpec.describe 'admin/schools/teachers/show.html.erb', type: :view do
  let(:school) { FactoryBot.create(:school) }
  let(:ect_teacher) { FactoryBot.create(:teacher) }
  let(:mentor_teacher) { FactoryBot.create(:teacher) }

  before do
    assign(:school, school)
    assign(:breadcrumbs, { "Schools" => "/admin/schools", school.name => nil })
    assign(:navigation_items, [
      { text: "Overview", href: admin_school_overview_path(school.urn), current: false },
      { text: "Teachers", href: admin_school_teachers_path(school.urn), current: true },
      { text: "Partnerships", href: admin_school_partnerships_path(school.urn), current: false }
    ])
    allow(view).to receive_messages(params: { urn: school.urn }, request: double(fullpath: "/admin/schools/#{school.urn}/teachers"))

    FactoryBot.create(:ect_at_school_period, :ongoing, teacher: ect_teacher, school:)
    FactoryBot.create(:mentor_at_school_period, :ongoing, teacher: mentor_teacher, school:)
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

  it 'renders the teachers table with teacher data' do
    render

    expect(rendered).to have_css('table.govuk-table')
    expect(rendered).to have_css('th', text: 'Name')
    expect(rendered).to have_css('th', text: 'TRN')
    expect(rendered).to have_css('th', text: 'Type')
    expect(rendered).to have_css('th', text: 'Contract period')
  end

  it 'marks teachers as current in navigation' do
    render

    expect(rendered).to have_css('.x-govuk-secondary-navigation__list-item--current a', text: 'Teachers')
    expect(rendered).to have_css('a[aria-current="page"]', text: 'Teachers')
  end
end
