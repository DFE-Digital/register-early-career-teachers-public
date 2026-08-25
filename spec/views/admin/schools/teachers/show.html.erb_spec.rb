RSpec.describe "admin/schools/teachers/show.html.erb", type: :view do
  let(:school) { FactoryBot.create(:school, create_contract_period: false) }
  let(:ect_teacher) { FactoryBot.create(:teacher) }
  let(:mentor_teacher) { FactoryBot.create(:teacher) }
  let!(:contract_period_2024) { FactoryBot.create(:contract_period, year: 2024) }
  let!(:contract_period_2025) { FactoryBot.create(:contract_period, year: 2025) }
  let(:teacher_rows) do
    [
      Admin::Teachers::Rows::Row.new(teacher: ect_teacher, role: "ect", contract_period: "2024"),
      Admin::Teachers::Rows::Row.new(teacher: mentor_teacher, role: "mentor", contract_period: "2025")
    ]
  end
  let(:has_current_teachers) { true }
  let(:request_params) { { school_urn: school.urn } }

  before do
    assign(:school, school)
    assign(:teacher_rows, teacher_rows)
    assign(:has_current_teachers, has_current_teachers)
    assign(:breadcrumbs, { "Schools" => "/admin/schools", school.name => nil })
    assign(:navigation_items, [
      { text: "Overview", href: admin_school_overview_path(school.urn), current: false },
      { text: "Teachers", href: admin_school_teachers_path(school.urn), current: true },
      { text: "Partnerships", href: admin_school_partnerships_path(school.urn), current: false },
      { text: "Timeline", href: admin_school_timeline_path(school.urn), current: false }
    ])
    allow(view).to receive(:params).and_return(request_params)
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
  end

  it "renders the teachers table" do
    render

    expect(rendered).to have_css("table.govuk-table")
  end

  it "renders the search form" do
    render

    expect(rendered).to have_css("form[action='#{admin_school_teachers_path(school.urn)}'][method='get']")
  end

  context "when filters return no teacher rows" do
    let(:teacher_rows) { [] }
    let(:request_params) { { school_urn: school.urn, role: "mentor" } }

    it "renders the filtered empty state" do
      render

      expect(rendered).to have_text("There are no teachers that match your search.")
    end
  end

  context "when the school has no current teachers" do
    let(:teacher_rows) { [] }
    let(:has_current_teachers) { false }

    it "does not render search controls" do
      render

      expect(rendered).to have_text("No teachers found at this school.")
      expect(rendered).not_to have_field("Search for teacher")
    end
  end

  it "marks teachers as current in navigation" do
    render

    expect(rendered).to have_css(".x-govuk-secondary-navigation__list-item--current a", text: "Teachers")
    expect(rendered).to have_css('a[aria-current="page"]', text: "Teachers")
  end
end
