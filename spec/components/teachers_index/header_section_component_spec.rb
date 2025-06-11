RSpec.describe TeachersIndex::HeaderSectionComponent, type: :component do
  subject(:rendered) { render_inline(component) }

  let(:component) do
    TeachersIndex::HeaderSectionComponent.new(
      status:,
      current_count:,
      open_count:,
      closed_count:
    )
  end

  let(:open_count) { 5 }
  let(:closed_count) { 3 }

  context 'when viewing open inductions' do
    let(:status) { 'open' }
    let(:current_count) { open_count }

    it 'renders correct heading text' do
      expect(rendered.css('h2').text).to include('5 open inductions')
    end

    it 'uses correct heading CSS classes' do
      expect(rendered.css('h2.govuk-heading-m').length).to eq(1)
    end

    context 'when closed inductions exist' do
      it 'renders navigation link to closed inductions' do
        expect(rendered.to_html).to include('View closed inductions (3)')
        expect(rendered.css('a[href*="status=closed"]').length).to eq(1)
      end

      it 'renders navigation link with correct styling' do
        expect(rendered.css('[class*="govuk-"][class*="padding-bottom"]').length).to eq(1)
      end
    end

    context 'when no closed inductions exist' do
      let(:closed_count) { 0 }

      it 'does not render navigation link' do
        expect(rendered.to_html).not_to include('View closed inductions')
        expect(rendered.css('[class*="govuk-"][class*="padding-bottom"]').length).to eq(0)
      end
    end
  end

  context 'when viewing closed inductions' do
    let(:status) { 'closed' }
    let(:current_count) { closed_count }

    it 'renders correct heading text' do
      expect(rendered.css('h2').text).to include('3 closed inductions')
    end

    it 'always renders navigation link to open inductions' do
      expect(rendered.to_html).to include('View open inductions (5)')
      expect(rendered.css('a').length).to eq(1)
    end

    it 'navigation link points to default teachers path' do
      expect(rendered.css('a[href*="/teachers"]').length).to eq(1)
      expect(rendered.css('a[href*="status=closed"]').length).to eq(0)
    end
  end

  context 'with singular counts' do
    let(:status) { 'open' }
    let(:current_count) { 1 }
    let(:open_count) { 1 }
    let(:closed_count) { 1 }

    it 'pluralizes correctly for single induction' do
      expect(rendered.css('h2').text).to include('1 open induction')
      expect(rendered.css('h2').text).not_to include('inductions')
    end

    it 'renders correct navigation text for singular counts' do
      expect(rendered.to_html).to include('View closed inductions (1)')
    end
  end

  context 'with zero counts' do
    let(:status) { 'open' }
    let(:current_count) { 0 }
    let(:open_count) { 0 }
    let(:closed_count) { 0 }

    it 'pluralizes correctly for zero inductions' do
      expect(rendered.css('h2').text).to include('0 open inductions')
    end
  end

  describe 'component behavior' do
    let(:status) { 'open' }
    let(:current_count) { open_count }

    it 'includes necessary helpers' do
      expect(component.class.included_modules).to include(GovukLinkHelper)
      expect(component.class.included_modules).to include(Rails.application.routes.url_helpers)
      expect(component.class.included_modules).to include(ActionView::Helpers::TextHelper)
    end

    describe '#heading_text' do
      it 'returns correct pluralized text' do
        expect(component.send(:heading_text)).to eq('5 open inductions')
      end
    end

    describe '#showing_closed?' do
      context 'when status is closed' do
        let(:status) { 'closed' }

        it 'returns true' do
          expect(component.send(:showing_closed?)).to be(true)
        end
      end

      context 'when status is open' do
        it 'returns false' do
          expect(component.send(:showing_closed?)).to be(false)
        end
      end
    end

    describe '#should_show_navigation_link?' do
      context 'when viewing closed inductions' do
        let(:status) { 'closed' }

        it 'always returns true' do
          expect(component.send(:should_show_navigation_link?)).to be(true)
        end
      end

      context 'when viewing open inductions' do
        context 'with closed inductions available' do
          it 'returns true' do
            expect(component.send(:should_show_navigation_link?)).to be(true)
          end
        end

        context 'with no closed inductions' do
          let(:closed_count) { 0 }

          it 'returns false' do
            expect(component.send(:should_show_navigation_link?)).to be(false)
          end
        end
      end
    end

    describe '#navigation_link_text' do
      context 'when viewing closed inductions' do
        let(:status) { 'closed' }

        it 'returns correct text for open link' do
          expect(component.send(:navigation_link_text)).to eq('View open inductions (5)')
        end
      end

      context 'when viewing open inductions' do
        it 'returns correct text for closed link' do
          expect(component.send(:navigation_link_text)).to eq('View closed inductions (3)')
        end
      end
    end
  end

  describe 'layout structure' do
    let(:status) { 'open' }
    let(:current_count) { open_count }

    it 'renders within grid layout' do
      expect(rendered.css('.govuk-grid-row .govuk-grid-column-full').length).to eq(1)
    end

    it 'renders heading within proper container' do
      expect(rendered.css('.govuk-grid-column-full h2').length).to eq(1)
    end
  end
end
