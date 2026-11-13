RSpec.describe "admin/induction_platforms/show.html.erb" do
  let(:induction_platform) { FactoryBot.create(:api_oauth_client, name: "Alpha Induction Platform") }
  let(:authorizations) { [] }

  before do
    assign(:induction_platform, induction_platform)
    assign(:authorizations, authorizations)
    assign(:breadcrumbs, {
      "Organisations" => admin_organisations_path,
      "Induction platforms" => admin_induction_platforms_path,
      induction_platform.name => nil,
    })
    render
  end

  it "sets the main heading and page title to the induction platform name" do
    expect(view.content_for(:page_title)).to eql("Alpha Induction Platform")
    expect(view.content_for(:page_header)).to have_css("h1", text: "Alpha Induction Platform")
  end

  it "renders breadcrumbs" do
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Organisations", href: admin_organisations_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Induction platforms", href: admin_induction_platforms_path)
    expect(view.content_for(:backlink_or_breadcrumb)).not_to have_link("Alpha Induction Platform")
  end

  it "describes the page" do
    expect(rendered).to have_css("p", text: "Appropriate bodies who've granted access to send data to DfE from Alpha Induction Platform.")
  end

  context "when appropriate bodies have granted access" do
    let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period, name: "Burns Slant Drilling Co.") }
    let(:authorizations) do
      [
        FactoryBot.create(:api_oauth_authorization, :with_token,
                          client: induction_platform,
                          appropriate_body_period:,
                          granted_by_name: "Sarah Jones",
                          created_at: Time.zone.local(2026, 8, 13, 12))
      ]
    end

    it "renders the table headings" do
      expect(rendered).to have_css("th", text: "Appropriate body")
      expect(rendered).to have_css("th", text: "Access given by")
      expect(rendered).to have_css("th", text: "Date access given")
    end

    it "links to the appropriate body" do
      expect(rendered).to have_link("Burns Slant Drilling Co.", href: admin_appropriate_body_path(appropriate_body_period))
    end

    it "shows who granted access and when" do
      expect(rendered).to have_css("td", text: "Sarah Jones")
      expect(rendered).to have_css("td", text: "13 August 2026")
    end

    it "does not show the empty message" do
      expect(rendered).not_to have_content("No appropriate bodies have granted access.")
    end
  end

  context "when no appropriate bodies have granted access" do
    it "shows the empty message instead of a table" do
      expect(rendered).to have_css("p", text: "No appropriate bodies have granted access.")
      expect(rendered).not_to have_css("table")
    end
  end
end
