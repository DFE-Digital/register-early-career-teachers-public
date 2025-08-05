RSpec.describe 'admin/delivery_partners/show.html.erb' do
  let(:delivery_partner) { FactoryBot.create(:delivery_partner, name: "Test Delivery Partner") }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }
  let(:partnership) do
    FactoryBot.create(
      :lead_provider_delivery_partnership,
      delivery_partner:,
      active_lead_provider:
    )
  end

  before do
    assign(:delivery_partner, delivery_partner)
    assign(:page, '2')
    assign(:q, 'search term')
    assign(:lead_provider_partnerships, [partnership])
  end

  it %(sets the page title to the delivery partner name) do
    render

    expect(view.content_for(:page_title)).to eql('Test Delivery Partner')
  end

  it 'includes backlink with preserved page and query parameters' do
    render

    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: admin_delivery_partners_path(page: 2, q: 'search term'))
  end

  it 'renders the Lead provider partners table caption' do
    render

    expect(rendered).to have_css('table caption', text: 'Lead provider partners')
  end

  it 'renders a table with lead provider partnerships' do
    render

    expect(rendered).to have_css('table.govuk-table')
    expect(rendered).to have_css('th', text: 'Year')
    expect(rendered).to have_css('th', text: 'Lead provider')
    expect(rendered).to have_css('tbody tr', count: 1)
  end

  it 'displays partnership details in the table' do
    render

    expect(rendered).to have_css('td', text: partnership.contract_period.year.to_s)
    expect(rendered).to have_css('td', text: partnership.lead_provider.name)
  end

  context 'when there are multiple partnerships' do
    let(:old_active_lead_provider) { FactoryBot.create(:active_lead_provider) }
    let(:new_active_lead_provider) { FactoryBot.create(:active_lead_provider) }
    let(:old_partnership) do
      FactoryBot.create(
        :lead_provider_delivery_partnership,
        delivery_partner:,
        active_lead_provider: old_active_lead_provider
      )
    end
    let(:new_partnership) do
      FactoryBot.create(
        :lead_provider_delivery_partnership,
        delivery_partner:,
        active_lead_provider: new_active_lead_provider
      )
    end

    before do
      # Ensure different years for ordering test
      old_contract_period = FactoryBot.create(:contract_period, year: 2021)
      new_contract_period = FactoryBot.create(:contract_period, year: 2023)
      old_active_lead_provider.update!(contract_period: old_contract_period)
      new_active_lead_provider.update!(contract_period: new_contract_period)

      assign(:lead_provider_partnerships, [new_partnership, old_partnership])
    end

    it 'displays multiple partnerships' do
      render

      expect(rendered).to have_css('tbody tr', count: 2)
      expect(rendered).to have_css('td', text: '2021')
      expect(rendered).to have_css('td', text: '2023')
    end
  end

  context 'when there are no partnerships' do
    before do
      assign(:lead_provider_partnerships, [])
    end

    it 'shows empty state message' do
      render

      expect(rendered).to have_css('p', text: 'No lead provider partnerships found for this delivery partner.')
      expect(rendered).not_to have_css('table.govuk-table')
    end
  end

  context 'when page parameters are nil' do
    before do
      assign(:page, nil)
      assign(:q, nil)
    end

    it 'still renders backlink without parameters' do
      render

      expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: admin_delivery_partners_path)
    end
  end
end
