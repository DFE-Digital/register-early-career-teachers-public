RSpec.describe TeachersIndex::SearchSectionComponent, type: :component do
  subject(:rendered) { render_inline(component) }

  let(:component) { TeachersIndex::SearchSectionComponent.new(status:, query:) }

  context 'when viewing open inductions' do
    let(:status) { 'open' }

    context 'with no query' do
      let(:query) { nil }

      it 'renders search form with correct label' do
        expect(rendered.css('label').text).to include('Search for an open induction by name or teacher reference number (TRN)')
      end

      it 'renders search input with no value' do
        input_element = rendered.css('input[name="q"]').first
        expect(input_element['value']).to be_blank
      end

      it 'renders hidden status field with open value' do
        hidden_input = rendered.css('input[name="status"][type="hidden"]').first
        expect(hidden_input['value']).to eq('open')
      end

      it 'renders reset button with correct path for open status' do
        expect(rendered).to have_link('Reset', href: '/appropriate-body/teachers')
      end
    end

    context 'with a query' do
      let(:query) { 'Alice Smith' }

      it 'renders search input with query value' do
        input_element = rendered.css('input[name="q"]').first
        expect(input_element['value']).to eq('Alice Smith')
      end

      it 'still renders correct label' do
        expect(rendered.css('label').text).to include('Search for an open induction by name or teacher reference number (TRN)')
      end

      it 'renders reset button with correct path for open status' do
        expect(rendered).to have_link('Reset', href: '/appropriate-body/teachers')
      end
    end
  end

  context 'when viewing closed inductions' do
    let(:status) { 'closed' }
    let(:query) { nil }

    it 'renders search form with correct label for closed status' do
      expect(rendered.css('label').text).to include('Search for an closed induction by name or teacher reference number (TRN)')
    end

    it 'renders hidden status field with closed value' do
      hidden_input = rendered.css('input[name="status"][type="hidden"]').first
      expect(hidden_input['value']).to eq('closed')
    end

    it 'renders reset button with correct path for closed status' do
      expect(rendered).to have_link('Reset', href: '/appropriate-body/teachers?status=closed')
    end
  end

  describe 'form structure' do
    let(:status) { 'open' }
    let(:query) { nil }

    it 'renders form with correct method and URL' do
      form = rendered.css('form').first
      expect(form['method']).to eq('get')
      expect(form['action']).to include('/teachers')
    end

    it 'renders form group with proper styling' do
      expect(rendered.css('.govuk-form-group').length).to eq(1)
    end

    it 'renders label with correct styling' do
      label = rendered.css('label').first
      expect(label['class']).to include('govuk-label')
      expect(label['class']).to include('govuk-label--s')
      expect(label['for']).to eq('q')
    end

    it 'renders hint text' do
      expect(rendered.css('.govuk-hint').text).to include('Enter a name or TRN')
    end

    it 'renders input with correct styling' do
      input = rendered.css('input[name="q"]').first
      expect(input['class']).to include('govuk-input')
    end

    it 'renders submit button with correct styling' do
      button = rendered.css('input[type="submit"]').first
      expect(button['class']).to include('govuk-button')
      expect(button['value']).to eq('Search')
    end

    it 'renders reset button with correct styling' do
      expect(rendered).to have_link('Reset', class: ['govuk-button', 'govuk-button--secondary'])
    end

    it 'renders button group with correct styling' do
      expect(rendered.css('.govuk-button-group').length).to eq(1)
    end

    it 'uses grid layout for input and button' do
      expect(rendered.css('.govuk-grid-row').length).to eq(2) # One outer, one for form layout
      expect(rendered.css('.govuk-grid-column-two-thirds').length).to eq(1)
      expect(rendered.css('.govuk-grid-column-one-third').length).to eq(1)
    end
  end

  describe 'component behavior' do
    let(:status) { 'open' }
    let(:query) { nil }

    it 'includes necessary helpers' do
      expect(component.class.included_modules).to include(Rails.application.routes.url_helpers)
      expect(component.class.included_modules).to include(GovukLinkHelper)
    end
  end

  describe 'edge cases' do
    let(:status) { 'open' }

    context 'with empty string query' do
      let(:query) { '' }

      it 'renders input with empty value' do
        input_element = rendered.css('input[name="q"]').first
        expect(input_element['value']).to eq('')
      end
    end

    context 'with special characters in query' do
      let(:query) { "O'Connor & Smith <test>" }

      it 'properly escapes query value' do
        input_element = rendered.css('input[name="q"]').first
        expect(input_element['value']).to eq("O'Connor & Smith <test>")
      end
    end
  end

  describe 'accessibility' do
    let(:status) { 'open' }
    let(:query) { nil }

    it 'associates label with input using for attribute' do
      label = rendered.css('label').first
      input = rendered.css('input[name="q"]').first
      expect(label['for']).to eq('q')
      expect(input['id']).to be_present
    end

    it 'provides hint text for user guidance' do
      expect(rendered.css('.govuk-hint').length).to eq(1)
      expect(rendered.css('.govuk-hint').text).to be_present
    end
  end
end
