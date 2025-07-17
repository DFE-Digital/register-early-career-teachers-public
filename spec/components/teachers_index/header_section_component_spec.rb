RSpec.describe TeachersIndex::HeaderSectionComponent, type: :component do
  include Rails.application.routes.url_helpers

  subject(:component) do
    TeachersIndex::HeaderSectionComponent.new(status:, current_count:, open_count:, closed_count:)
  end

  let(:open_count) { 5 }
  let(:closed_count) { 3 }
  let(:status) { 'open' }
  let(:current_count) { open_count }
  let(:rendered) { render_inline(component) }
  let(:subheading) { rendered.css('h2.govuk-heading-m') }

  context 'when viewing open inductions' do
    it 'has correct subheading' do
      expect(subheading).to have_text('5 open inductions')
    end

    context 'when closed inductions exist' do
      it 'links to closed inductions' do
        expect(rendered).to have_link('View closed inductions (3)', href: closed_ab_teachers_path)
        expect(rendered.css('[class*="govuk-"][class*="padding-bottom"]').length).to eq(1)
      end
    end

    context 'when no closed inductions exist' do
      let(:closed_count) { 0 }

      it 'does not link to closed inductions' do
        expect(rendered).to have_text('No closed inductions')
        expect(rendered).not_to have_link('No closed inductions')
        # Should still render the padding container
        expect(rendered.css('[class*="govuk-"][class*="padding-bottom"]').length).to eq(1)
      end
    end
  end

  context 'when viewing closed inductions' do
    let(:status) { 'closed' }
    let(:current_count) { closed_count }

    it 'has correct subheading' do
      expect(subheading).to have_text('3 closed inductions')
    end

    it 'links to open inductions' do
      expect(rendered).to have_link('View open inductions (5)', href: open_ab_teachers_path)
    end
  end

  describe 'pluralization' do
    context 'with one induction' do
      let(:open_count) { 1 }
      let(:closed_count) { 1 }

      it 'is not plural' do
        expect(subheading).to have_text('1 open induction')
        expect(subheading).not_to have_text('inductions')
      end
    end

    context 'with no inductions' do
      let(:open_count) { 0 }
      let(:closed_count) { 0 }

      it 'is plural' do
        expect(subheading).to have_text('0 open inductions')
      end
    end
  end

  describe 'layout structure' do
    it 'renders within grid layout' do
      expect(rendered.css('.govuk-grid-row .govuk-grid-column-full').length).to eq(1)
    end

    it 'renders heading within proper container' do
      expect(rendered.css('.govuk-grid-column-full h2').length).to eq(1)
    end
  end
end
