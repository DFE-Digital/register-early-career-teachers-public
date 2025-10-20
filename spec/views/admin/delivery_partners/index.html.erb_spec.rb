RSpec.describe "admin/delivery_partners/index.html.erb" do
  let(:number_of_delivery_partners) { 10 }
  let(:delivery_partners) { FactoryBot.create_list(:delivery_partner, number_of_delivery_partners) }
  let(:pagy) { Pagy.new(count: number_of_delivery_partners, limit: 5, page: 1) }

  before do
    assign(:delivery_partners, delivery_partners)
    assign(:pagy, pagy)
    assign(:breadcrumbs, {
      "Organisations" => admin_organisations_path,
      "Delivery partners" => nil
    })
  end

  it %(sets the main heading and page title to 'Delivery partners') do
    render

    expect(view.content_for(:page_title)).to eql("Delivery partners")
    expect(view.content_for(:page_header)).to have_css("h1", text: "Delivery partners")
  end

  it "renders breadcrumbs with correct links" do
    render

    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Organisations", href: admin_organisations_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to include("Delivery partners")
    expect(view.content_for(:backlink_or_breadcrumb)).not_to have_link("Delivery partners")
  end

  it "renders the search section" do
    render

    expect(rendered).to have_css("label", text: "Search for delivery partner")
    expect(rendered).to have_field("q")
  end

  it "renders a table of delivery partners" do
    render

    expect(rendered).to have_css("table.govuk-table")
    expect(rendered).to have_css("tbody tr", count: number_of_delivery_partners)
  end

  it "includes links by name to the individual delivery partner pages" do
    render

    delivery_partners.each do |delivery_partner|
      expect(rendered).to have_link(delivery_partner.name)
    end
  end

  it "renders the search form" do
    render

    expect(rendered).to have_css("form")
    expect(rendered).to have_field("q")
    expect(rendered).to have_button("Search")
  end

  it "renders pagination and results summary when delivery partners are present" do
    render

    expect(rendered).to have_css(".govuk-pagination")
    expect(rendered).to have_css("div.govuk-body", text: "Showing 1 to 5 of 10 results")
  end

  context "when there are no delivery partners" do
    let(:number_of_delivery_partners) { 0 }

    it "shows no delivery partners found message" do
      render

      expect(rendered).to have_css("p", text: "No delivery partners found.")
      expect(rendered).not_to have_css("table.govuk-table")
    end
  end

  context "when search query returns no results" do
    let(:delivery_partners) { [] }

    before do
      controller.params[:q] = "nonexistent delivery partner"
    end

    it "shows no matching delivery partners message" do
      render

      expect(rendered).to have_css("p", text: "There are no delivery partners that match your search.")
      expect(rendered).not_to have_css("table.govuk-table")
    end
  end

  it "renders table with only Delivery partner column" do
    render

    expect(rendered).to have_css("table.govuk-table")
    expect(rendered).to have_css("th", text: "Delivery partner")
  end

  it "preserves page and query parameters in links" do
    controller.params[:page] = "2"
    controller.params[:q] = "search term"

    render

    delivery_partners.each do |delivery_partner|
      expect(rendered).to have_link(
        delivery_partner.name,
        href: admin_delivery_partner_path(delivery_partner, page: "2", q: "search term")
      )
    end
  end
end
