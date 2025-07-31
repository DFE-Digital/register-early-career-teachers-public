RSpec.describe 'admin/appropriate_bodies/index.html.erb' do
  include Pagy::Backend

  let(:number_of_appropriate_bodies) { 2 }
  let(:appropriate_bodies) { FactoryBot.create_list(:appropriate_body, number_of_appropriate_bodies) }
  let(:pagy) { pagy_array(appropriate_bodies, items: 5, page: 1) }

  before do
    assign(:appropriate_bodies, appropriate_bodies)
    assign(:pagy, pagy)
    assign(:breadcrumbs, {
      "Organisations" => admin_organisations_path,
      "Appropriate bodies" => nil,
    })
  end

  it %(sets the main heading and page title to 'Appropriate bodies') do
    render

    expect(view.content_for(:page_title)).to eql('Appropriate bodies')
    expect(view.content_for(:page_header)).to have_css('h1', text: 'Appropriate bodies')
  end

  it 'renders breadcrumbs' do
    render

    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Organisations', href: admin_organisations_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to include('Appropriate bodies')
    expect(view.content_for(:backlink_or_breadcrumb)).not_to have_link('Appropriate bodies')
  end

  it "renders a link to view all bulk uploads" do
    render

    expect(rendered).to have_link("View all bulk uploads", href: admin_bulk_batches_path)
  end

  it 'renders a list of appropriate bodies' do
    render

    expect(rendered).to have_css('.govuk-summary-card', count: number_of_appropriate_bodies)
  end

  it 'includes links by name to the individual appropriate body pages' do
    render

    appropriate_bodies.each do |appropriate_body|
      expect(rendered).to have_link(appropriate_body.name, href: admin_appropriate_body_path(appropriate_body))
    end
  end
end
