RSpec.describe 'admin/schools/show.html.erb' do
  let(:school) { FactoryBot.create(:school, urn: '100001', induction_tutor_name: 'John Jones', induction_tutor_email: 'abc@email.com') }

  before do
    assign(:school, school)
    assign(:breadcrumbs, {
      "Schools" => admin_schools_path(page: '1', q: 'test'),
      school.name => nil
    })
    allow(view).to receive(:params).and_return(page: '1', q: 'test')
  end

  it 'displays school URN in caption and name as H1' do
    render

    expect(view.content_for(:page_caption)).to have_css('.govuk-caption-xl', text: 'URN: 100001')
    expect(view.content_for(:page_header)).to have_css('h1.govuk-heading-xl', text: school.name)
  end

  it 'sets up breadcrumbs in page data' do
    render

    expect(view.content_for(:backlink_or_breadcrumb)).to include('govuk-breadcrumbs')
    expect(view.content_for(:backlink_or_breadcrumb)).to include('Schools')
    expect(view.content_for(:backlink_or_breadcrumb)).to include(school.name)
  end

  it 'displays tabs navigation' do
    render

    expect(rendered).to have_css('.govuk-tabs')
    expect(rendered).to have_css('.govuk-tabs__list')
    expect(rendered).to have_css('a.govuk-tabs__tab', text: 'Overview')
    expect(rendered).to have_css('a.govuk-tabs__tab', text: 'Teachers')
    expect(rendered).to have_css('a.govuk-tabs__tab', text: 'Partnerships')
  end

  describe 'Overview section' do
    it 'renders the overview component' do
      render

      expect(rendered).to have_css('.govuk-tabs__panel')
      expect(rendered).to have_css('.govuk-summary-list')
    end
  end

  describe 'Teachers section' do
    it 'renders the teachers table component' do
      render

      expect(rendered).to have_css('.govuk-tabs__panel')
    end
  end

  describe 'Partnerships section' do
    it 'displays placeholder content' do
      render

      expect(rendered).to have_css('.govuk-tabs__panel')
      expect(rendered).to have_css('p', text: 'Partnership information will be available here in the future.')
    end
  end
end
