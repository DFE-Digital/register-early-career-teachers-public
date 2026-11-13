RSpec.describe "admin/induction_platforms/index.html.erb" do
  let(:induction_platform) { FactoryBot.create(:api_oauth_client, name: "Alpha Induction Platform") }

  before do
    assign(:induction_platforms, [induction_platform])
    assign(:breadcrumbs, {
      "Organisations" => admin_organisations_path,
      "Induction platforms" => nil,
    })
    render
  end

  it "sets the main heading and page title to 'Induction platforms'" do
    expect(view.content_for(:page_title)).to eql("Induction platforms")
    expect(view.content_for(:page_header)).to have_css("h1", text: "Induction platforms")
  end

  it "renders breadcrumbs" do
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link("Organisations", href: admin_organisations_path)
    expect(view.content_for(:backlink_or_breadcrumb)).not_to have_link("Induction platforms")
  end

  it "links to each induction platform" do
    expect(rendered).to have_css("th", text: "Induction platform")
    expect(rendered).to have_link("Alpha Induction Platform", href: admin_induction_platform_path(induction_platform))
  end
end
