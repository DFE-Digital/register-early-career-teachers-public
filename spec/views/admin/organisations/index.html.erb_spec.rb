RSpec.describe "admin/organisations/index.html.erb" do
  it %(sets the main heading and page title to 'Organisations') do
    render

    expect(view.content_for(:page_title)).to eql("Organisations")
    expect(view.content_for(:page_header)).to have_css("h1", text: "Organisations")
  end

  it "links to each organisation type" do
    render

    expect(rendered).to have_link("Appropriate bodies", href: admin_appropriate_bodies_path)
    expect(rendered).to have_link("Lead providers", href: admin_lead_providers_path)
    expect(rendered).to have_link("Delivery partners", href: admin_delivery_partners_path)
    expect(rendered).to have_link("Teaching school hubs", href: admin_teaching_school_hubs_path)
  end
end
