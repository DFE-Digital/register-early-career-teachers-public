describe "admin/schools/timeline/show.html.erb" do
  let(:gias_school) { FactoryBot.build(:gias_school) }
  let(:school) { FactoryBot.build(:school, gias_school:) }
  let(:number_of_events) { 3 }
  let(:events) { FactoryBot.build_list(:event, number_of_events) }

  before do
    assign(:school, school)
    assign(:breadcrumbs, { "Schools" => "/admin/schools", school.name => nil })
    assign(:navigation_items, [
      { text: "Overview", href: admin_school_overview_path(school.urn), current: false },
      { text: "Teachers", href: admin_school_teachers_path(school.urn), current: false },
      { text: "Partnerships", href: admin_school_partnerships_path(school.urn), current: false },
      { text: "Timeline", href: admin_school_timeline_path(school.urn), current: true }
    ])
    assign(:events, events)
    allow(view).to receive_messages(params: { urn: school.urn }, request: double(fullpath: "/admin/schools/#{school.urn}/timeline"))
  end

  it "sets up breadcrumbs in page data" do
    render

    expect(view.content_for(:backlink_or_breadcrumb)).to include("govuk-breadcrumbs")
    expect(view.content_for(:backlink_or_breadcrumb)).to include("Schools")
    expect(view.content_for(:backlink_or_breadcrumb)).to include(school.name)
  end

  it "displays school URN in caption and name as H1" do
    render

    expect(view.content_for(:page_caption)).to include("URN: #{school.urn}")
    expect(view.content_for(:page_header)).to include(school.name)
  end

  it "has an impersonation button" do
    render

    expect(rendered).to have_css(".govuk-button", text: "Sign in as #{school.name}")
  end

  it "displays secondary navigation" do
    render

    expect(rendered).to have_css("nav.x-govuk-secondary-navigation")
    expect(rendered).to have_css("ul.x-govuk-secondary-navigation__list")
    expect(rendered).to have_css("a", text: "Overview")
    expect(rendered).to have_css("a", text: "Teachers")
    expect(rendered).to have_css("a", text: "Partnerships")
    expect(rendered).to have_css("li.x-govuk-secondary-navigation__list-item--current > a", text: "Timeline")
  end

  context "when there are no events" do
    before { assign(:events, []) }

    it "displays the 'no events' message" do
      render

      expect(rendered).to have_css("p", text: "No timeline of events for this school.")
    end
  end

  context "when there are events" do
    it "displays the timeline component" do
      render

      expect(rendered).to have_css(".app-timeline")
      expect(rendered).to have_css(".app-timeline__item", count: number_of_events)
    end
  end
end
