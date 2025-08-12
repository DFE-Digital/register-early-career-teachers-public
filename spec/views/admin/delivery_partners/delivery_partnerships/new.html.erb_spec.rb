RSpec.describe 'admin/delivery_partners/delivery_partnerships/new.html.erb' do
  let(:delivery_partner) { FactoryBot.create(:delivery_partner, name: "Test Delivery Partner") }
  let(:contract_period) { FactoryBot.create(:contract_period, year: 2025) }
  let(:lead_provider_1) { FactoryBot.create(:lead_provider, name: "Lead Provider 1") }
  let(:lead_provider_2) { FactoryBot.create(:lead_provider, name: "Lead Provider 2") }
  let(:active_lead_provider_1) { FactoryBot.create(:active_lead_provider, lead_provider: lead_provider_1, contract_period:) }
  let(:active_lead_provider_2) { FactoryBot.create(:active_lead_provider, lead_provider: lead_provider_2, contract_period:) }

  before do
    assign(:delivery_partner, delivery_partner)
    assign(:year, 2025)
    assign(:contract_period, contract_period)
    assign(:page, '2')
    assign(:q, 'search term')
    assign(:current_partnerships, [])
    assign(:available_lead_providers, [active_lead_provider_1, active_lead_provider_2])
  end

  it 'sets the page title' do
    render

    expect(view.content_for(:page_title)).to eq('Select lead providers working with Test Delivery Partner in 2025')
  end

  it 'includes backlink to delivery partner show page' do
    render

    expected_href = admin_delivery_partner_path(delivery_partner, page: 2, q: 'search term')
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: expected_href)
  end

  it 'renders a form that submits to the create action' do
    render

    expected_action = admin_delivery_partner_delivery_partnership_path(delivery_partner, 2025)
    expect(rendered).to have_css("form[action='#{expected_action}'][method='post']")
    expect(rendered).not_to have_css("input[name='_method'][value='patch']", visible: :hidden)
  end

  it 'includes hidden fields for year, page, and query parameters' do
    render

    expect(rendered).to have_css("input[name='year'][value='2025']", visible: :hidden)
    expect(rendered).to have_css("input[name='page'][value='2']", visible: :hidden)
    expect(rendered).to have_css("input[name='q'][value='search term']", visible: :hidden)
  end

  it 'renders checkboxes for available lead providers' do
    render

    expect(rendered).to have_css("input[type='checkbox'][value='#{active_lead_provider_1.id}']")
    expect(rendered).to have_css("input[type='checkbox'][value='#{active_lead_provider_2.id}']")
    expect(rendered).to have_css('label', text: 'Lead Provider 1')
    expect(rendered).to have_css('label', text: 'Lead Provider 2')
  end

  it 'renders confirm button' do
    render

    expect(rendered).to have_button('Confirm')
  end

  context 'with existing partnerships' do
    let(:current_partnership) do
      FactoryBot.create(
        :lead_provider_delivery_partnership,
        delivery_partner:,
        active_lead_provider: active_lead_provider_1
      )
    end

    before do
      assign(:current_partnerships, [current_partnership])
      # Only show lead provider 2 as available since lead provider 1 is already assigned
      assign(:available_lead_providers, [active_lead_provider_2])
    end

    it 'displays currently working lead providers' do
      render

      expect(rendered).to have_css('.govuk-inset-text')
      expect(rendered).to have_css('h3', text: 'Currently working with:')
      expect(rendered).to have_css('li', text: 'Lead Provider 1')
    end

    it 'only shows unassigned lead providers as checkboxes' do
      render

      expect(rendered).not_to have_css("input[type='checkbox'][value='#{active_lead_provider_1.id}']")
      expect(rendered).to have_css("input[type='checkbox'][value='#{active_lead_provider_2.id}']")
    end
  end

  context 'when page parameters are nil' do
    before do
      assign(:page, nil)
      assign(:q, nil)
    end

    it 'still renders backlink and hidden fields without parameters' do
      render

      expected_href = admin_delivery_partner_path(delivery_partner)
      expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: expected_href)
      expect(rendered).to have_css("input[name='page']", visible: :hidden)
      expect(rendered).to have_css("input[name='q']", visible: :hidden)
    end
  end
end
