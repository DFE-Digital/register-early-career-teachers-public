RSpec.describe "admin/schools/index.html.erb" do
  include Pagy::Backend

  let(:number_of_schools) { 10 }
  let(:schools) { FactoryBot.create_list(:school, number_of_schools) }
  let(:pagy) { Pagy.new(count: number_of_schools, limit: 5, page: 1) }

  before do
    assign(:schools, schools)
    assign(:pagy, pagy)
  end

  it %(sets the main heading and page title to 'Schools') do
    render

    expect(view.content_for(:page_title)).to eql("Schools")
    expect(view.content_for(:page_header)).to have_css("h1", text: "Schools")
  end

  it "renders the search section" do
    render

    expect(rendered).to have_css("label", text: "Search by name or URN")
    expect(rendered).to have_field("q")
  end

  it "renders a table of schools" do
    render

    expect(rendered).to have_css("table.govuk-table")
    expect(rendered).to have_css("tbody tr", count: number_of_schools)
  end

  it "includes links by name to the individual school pages" do
    render

    schools.each do |school|
      expect(rendered).to have_link(school.name)
    end
  end

  it "renders the search form" do
    render

    expect(rendered).to have_css("form")
    expect(rendered).to have_field("q")
    expect(rendered).to have_button("Search")
  end

  it "renders pagination and results summary when schools are present" do
    render

    expect(rendered).to have_css(".govuk-pagination")
    expect(rendered).to have_css("div.govuk-body", text: "Showing 1 to 5 of 10 results")
  end

  context "when there are no schools" do
    let(:schools) { [] }
    let(:number_of_schools) { 0 }

    it "shows no schools found message" do
      render

      expect(rendered).to have_css("p", text: "No schools found.")
      expect(rendered).not_to have_css("table.govuk-table")
    end
  end

  context "when search query returns no results" do
    let(:schools) { [] }
    let(:number_of_schools) { 0 }

    before do
      controller.params[:q] = "nonexistent school"
    end

    it "shows no matching schools message" do
      render

      expect(rendered).to have_css("p", text: "There are no schools that match your search.")
      expect(rendered).not_to have_css("table.govuk-table")
    end
  end

  it "renders table with only School and URN columns" do
    render

    expect(rendered).to have_css("table.govuk-table")
    expect(rendered).to have_css("th", text: "School")
    expect(rendered).to have_css("th", text: "URN")
    expect(rendered).not_to have_css("th", text: "Postcode")
  end
end
