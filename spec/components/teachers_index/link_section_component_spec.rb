RSpec.describe TeachersIndex::LinkSectionComponent, type: :component do
  subject(:rendered) { render_inline(component) }

  let(:component) { TeachersIndex::LinkSectionComponent.new(bulk_upload_enabled:) }

  context 'when bulk upload is enabled' do
    let(:bulk_upload_enabled) { true }

    it 'renders all expected links' do
      expect(rendered.css('a').length).to eq(3) # Find ECT + 2 bulk upload links

      # Find ECT link
      expect(rendered.to_html).to include('Find and claim a new ECT')

      # Bulk upload links
      expect(rendered.to_html).to include('Upload a CSV to record outcomes for multiple ECTs')
      expect(rendered.to_html).to include('Upload a CSV to claim multiple new ECTs')
    end

    it 'renders section break after links' do
      expect(rendered.css('.govuk-section-break').length).to eq(1)
    end

    it 'renders within grid layout' do
      expect(rendered.css('.govuk-grid-row .govuk-grid-column-full').length).to eq(1)
    end
  end

  context 'when bulk upload is disabled' do
    let(:bulk_upload_enabled) { false }

    it 'renders the find ECT link' do
      expect(rendered.to_html).to include('Find and claim a new ECT')
    end

    it 'does not render bulk upload links' do
      expect(rendered.to_html).not_to include('Upload a CSV to record outcomes')
      expect(rendered.to_html).not_to include('Upload a CSV to claim multiple')
    end

    it 'still renders section break' do
      expect(rendered.css('.govuk-section-break').length).to eq(1)
    end
  end

  describe 'component behavior' do
    let(:bulk_upload_enabled) { true }

    it 'includes necessary helpers' do
      expect(component.class.included_modules).to include(GovukLinkHelper)
      expect(component.class.included_modules).to include(Rails.application.routes.url_helpers)
    end

    it 'correctly evaluates bulk_upload_enabled?' do
      expect(component.send(:bulk_upload_enabled?)).to be(true)

      disabled_component = TeachersIndex::LinkSectionComponent.new(bulk_upload_enabled: false)
      expect(disabled_component.send(:bulk_upload_enabled?)).to be(false)
    end
  end
end
