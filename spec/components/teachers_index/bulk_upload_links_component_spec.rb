RSpec.describe TeachersIndex::BulkUploadLinksComponent, type: :component do
  before { render_inline(component) }

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:component) { described_class.new(appropriate_body:) }

  it 'links to Find ECTs' do
    expect(page).to have_link('Find and claim a new ECT', href: '/appropriate-body/claim-an-ect/find-ect/new')
  end

  context 'without existing bulk submissions' do
    it 'links to new bulk claim page' do
      expect(page).to have_link('Upload a CSV to claim multiple new ECTs', href: '/appropriate-body/bulk/claims/new')
    end

    it 'links to new bulk action page' do
      expect(page).to have_link('Upload a CSV to record outcomes', href: '/appropriate-body/bulk/actions/new')
    end
  end

  context 'with existing bulk action submissions' do
    before do
      FactoryBot.create(:pending_induction_submission_batch, :action, appropriate_body:)
      render_inline(component)
    end

    it 'links to batch actions history' do
      expect(page).to have_link('Upload a CSV to record outcomes for multiple ECTs', href: '/appropriate-body/bulk/actions')
    end
  end

  context 'with existing bulk claim submissions', skip: 'TODO' do
    before do
      FactoryBot.create(:pending_induction_submission_batch, :claim, appropriate_body:)
      render_inline(component)
    end

    it 'links to bulk claims history' do
      expect(page).to have_link('Upload a CSV to claim multiple new ECTs', href: '/appropriate-body/bulk/claims')
    end
  end
end
