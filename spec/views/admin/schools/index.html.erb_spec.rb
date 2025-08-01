RSpec.describe 'admin/schools/index.html.erb' do
  include Pagy::Backend

  let(:number_of_schools) { 2 }
  let(:schools) { FactoryBot.create_list(:school, number_of_schools) }
  let(:pagy) { Pagy.new(count: number_of_schools, limit: 5, page: 1) }

  before do
    assign(:schools, schools)
    assign(:pagy, pagy)
    assign(:q, "")
    assign(:page, 1)
    assign(:breadcrumbs, {
      "Organisations" => admin_organisations_path,
      "Schools" => nil,
    })
  end

  it %(sets the main heading and page title to 'Schools') do
    render

    expect(view.content_for(:page_title)).to eql('Schools')
    expect(view.content_for(:page_header)).to have_css('h1', text: 'Schools')
  end

  it 'renders breadcrumbs' do
    render

    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Organisations', href: admin_organisations_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to include('Schools')
    expect(view.content_for(:backlink_or_breadcrumb)).not_to have_link('Schools')
  end

  it 'renders a table of schools' do
    render

    expect(rendered).to have_css('table.govuk-table')
    expect(rendered).to have_css('tbody tr', count: number_of_schools)
  end

  it 'includes links by name to the individual school pages' do
    render

    schools.each do |school|
      expect(rendered).to have_link(school.name, href: admin_school_path(school, page: 1, q: ""))
    end
  end
end
