RSpec.describe TeachersIndex::BulkUploadLinksComponent, type: :component do
  let(:appropriate_body) { create(:appropriate_body) }
  let(:component) { described_class.new(appropriate_body:) }

  describe 'rendered content' do
    subject { render_inline(component) }

    it 'renders the grid structure' do
      expect(subject.css('.govuk-grid-row').length).to eq(1)
      expect(subject.css('.govuk-grid-column-full').length).to eq(1)
    end

    it 'always renders the find ECT link' do
      expect(subject.to_html).to include('Find and claim a new ECT')
      expect(subject.css('a[href*="find"]').length).to eq(1)
    end

    it 'always renders the section break' do
      expect(subject.css('.govuk-section-break').length).to eq(1)
    end

    context 'when both bulk upload and bulk claim are disabled' do
      before do
        allow(Rails.application.config).to receive_messages(enable_bulk_upload: false, enable_bulk_claim: false)
      end

      it 'does not render bulk upload links' do
        expect(subject.to_html).not_to include('Upload a CSV to record outcomes')
        expect(subject.to_html).not_to include('Upload a CSV to claim multiple')
      end

      it 'only renders the find ECT link' do
        links = subject.css('a')
        expect(links.length).to eq(1)
        expect(links.first.text).to include('Find and claim a new ECT')
      end
    end

    context 'when bulk upload is enabled but bulk claim is disabled' do
      before do
        allow(Rails.application.config).to receive_messages(enable_bulk_upload: true, enable_bulk_claim: false)
      end

      it 'renders bulk upload link but not bulk claim link' do
        expect(subject.to_html).to include('Upload a CSV to record outcomes')
        expect(subject.to_html).not_to include('Upload a CSV to claim multiple')
      end

      context 'when no existing bulk uploads exist' do
        it 'links directly to new batch action page' do
          expect(subject.css('a[href*="bulk/actions/new"]').length).to eq(1)
        end
      end

      context 'when existing bulk uploads exist' do
        before do
          create(:pending_induction_submission_batch, :action, appropriate_body:)
        end

        it 'links to batch actions index page' do
          expect(subject.css('a[href*="bulk/actions"][href$="actions"]').length).to eq(1)
          expect(subject.css('a[href*="bulk/actions/new"]').length).to eq(0)
        end
      end
    end

    context 'when bulk claim is enabled but bulk upload is disabled' do
      before do
        allow(Rails.application.config).to receive_messages(enable_bulk_upload: false, enable_bulk_claim: true)
      end

      it 'renders bulk claim link but not bulk upload link' do
        expect(subject.to_html).to include('Upload a CSV to claim multiple')
        expect(subject.to_html).not_to include('Upload a CSV to record outcomes')
      end

      it 'links to new batch claim page' do
        expect(subject.css('a[href*="bulk/claims/new"]').length).to eq(1)
      end
    end

    context 'when both bulk upload and bulk claim are enabled' do
      before do
        allow(Rails.application.config).to receive_messages(enable_bulk_upload: true, enable_bulk_claim: true)
      end

      it 'renders both bulk upload and bulk claim links' do
        expect(subject.to_html).to include('Upload a CSV to record outcomes')
        expect(subject.to_html).to include('Upload a CSV to claim multiple')
      end

      it 'renders all three links' do
        links = subject.css('a')
        expect(links.length).to eq(3)
      end

      context 'when no existing bulk uploads exist' do
        it 'bulk actions link goes to new page' do
          expect(subject.css('a[href*="bulk/actions/new"]').length).to eq(1)
        end
      end

      context 'when existing bulk uploads exist' do
        before do
          create(:pending_induction_submission_batch, :action, appropriate_body:)
        end

        it 'bulk actions link goes to index page' do
          expect(subject.css('a[href*="bulk/actions"][href$="actions"]').length).to eq(1)
          expect(subject.css('a[href*="bulk/actions/new"]').length).to eq(0)
        end
      end
    end
  end

  describe '#has_existing_bulk_uploads?' do
    context 'when no bulk uploads exist' do
      it 'returns false' do
        expect(component.send(:has_existing_bulk_uploads?)).to be false
      end
    end

    context 'when bulk uploads exist for this appropriate body' do
      before do
        create(:pending_induction_submission_batch, :action, appropriate_body:)
      end

      it 'returns true' do
        expect(component.send(:has_existing_bulk_uploads?)).to be true
      end
    end

    context 'when bulk uploads exist for other appropriate bodies only' do
      let(:other_appropriate_body) { create(:appropriate_body) }

      before do
        create(:pending_induction_submission_batch, :action, appropriate_body: other_appropriate_body)
      end

      it 'returns false' do
        expect(component.send(:has_existing_bulk_uploads?)).to be false
      end
    end

    context 'when bulk claims exist but no bulk actions' do
      before do
        create(:pending_induction_submission_batch, :claim, appropriate_body:)
      end

      it 'returns false' do
        expect(component.send(:has_existing_bulk_uploads?)).to be false
      end
    end
  end

  describe 'batch action path routing' do
    subject { render_inline(component) }

    before do
      allow(Rails.application.config).to receive(:enable_bulk_upload).and_return(true)
    end

    context 'when no existing bulk uploads exist' do
      it 'routes to new batch action page' do
        expect(subject.css('a[href*="bulk/actions/new"]').length).to eq(1)
      end
    end

    context 'when existing bulk uploads exist' do
      before do
        create(:pending_induction_submission_batch, :action, appropriate_body:)
      end

      it 'routes to batch actions index page' do
        expect(subject.css('a[href*="bulk/actions"][href$="actions"]').length).to eq(1)
        expect(subject.css('a[href*="bulk/actions/new"]').length).to eq(0)
      end
    end
  end

  describe 'feature flag methods' do
    describe '#bulk_upload_enabled?' do
      it 'returns the Rails config value' do
        allow(Rails.application.config).to receive(:enable_bulk_upload).and_return(true)
        expect(component.send(:bulk_upload_enabled?)).to be true

        allow(Rails.application.config).to receive(:enable_bulk_upload).and_return(false)
        expect(component.send(:bulk_upload_enabled?)).to be false
      end
    end

    describe '#bulk_claim_enabled?' do
      it 'returns the Rails config value' do
        allow(Rails.application.config).to receive(:enable_bulk_claim).and_return(true)
        expect(component.send(:bulk_claim_enabled?)).to be true

        allow(Rails.application.config).to receive(:enable_bulk_claim).and_return(false)
        expect(component.send(:bulk_claim_enabled?)).to be false
      end
    end
  end
end
