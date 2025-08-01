RSpec.describe 'admin/lead_providers/index.html.erb' do
  let(:number_of_lead_providers) { 2 }
  let(:lead_providers) { FactoryBot.create_list(:lead_provider, number_of_lead_providers) }

  before do
    assign(:lead_providers, lead_providers)
    assign(:breadcrumbs, {
      "Organisations" => admin_organisations_path,
      "Lead providers" => nil,
    })
  end

  it %(sets the main heading and page title to 'Lead providers') do
    render

    expect(view.content_for(:page_title)).to eql('Lead providers')
    expect(view.content_for(:page_header)).to have_css('h1', text: 'Lead providers')
  end

  it 'renders breadcrumbs' do
    render

    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Organisations', href: admin_organisations_path)
    expect(view.content_for(:backlink_or_breadcrumb)).to include('Lead providers')
    expect(view.content_for(:backlink_or_breadcrumb)).not_to have_link('Lead providers')
  end

  it 'renders a table of lead providers' do
    render

    expect(rendered).to have_css('table.govuk-table')
    expect(rendered).to have_css('tbody tr', count: number_of_lead_providers)
  end

  it 'displays lead provider names' do
    render

    lead_providers.each do |lead_provider|
      expect(rendered).to include(lead_provider.name)
    end
  end
end
