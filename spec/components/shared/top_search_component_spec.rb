RSpec.describe Shared::TopSearchComponent, type: :component do
  before { render_inline(component) }

  context 'default' do
    let(:component) { described_class.new }

    it 'renders a text field with the default label and value from params' do
      expect(rendered_content).to have_css('label.govuk-label', text: 'Search by name or teacher reference number (TRN)')
    end

    it 'renders a search button with default text' do
      expect(rendered_content).to have_button('Search')
    end

    it "sets query_param from the argument" do
      expect(component.query_param).to eq(:q)
    end

    it 'defaults url to nil when none provided' do
      expect(component.url).to be_nil
    end
  end

  context "with custom options" do
    let(:component) { described_class.new(query_param: :search_term, label_text: 'Custom Label', submit_text: 'Go', url: '/custom_path') }

    it 'renders a text field with the custom label and value from params' do
      expect(rendered_content).to have_css('label.govuk-label', text: 'Custom Label')
    end

    it 'renders a submit button with the custom text' do
      expect(rendered_content).to have_button('Go')
    end

    it "sets query_param from the argument" do
      expect(component.query_param).to eq(:search_term)
    end

    it 'sets url from the argument' do
      expect(component.url).to eq('/custom_path')
    end
  end
end
