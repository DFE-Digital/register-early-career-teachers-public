RSpec.describe Admin::AppropriateBodies::BulkUploadComponent, type: :component do
  subject(:component) { described_class.new(batch:) }

  let(:batch) do
    FactoryBot.create(:pending_induction_submission_batch, :claim, :completed)
  end

  describe "#batch_cards" do
    let(:subcomponent) { ::Admin::AppropriateBodies::Batches::BatchCardsComponent }

    before do
      allow(subcomponent).to receive(:new).and_call_original
      render_inline(component, &:with_batch_cards)
    end

    it "passes the batch to subcomponent" do
      expect(subcomponent).to have_received(:new).with(batch:)
    end
  end

  describe "#batch_details" do
    let(:subcomponent) { ::Admin::AppropriateBodies::Batches::BatchDetailsComponent }

    before do
      allow(subcomponent).to receive(:new).and_call_original
      render_inline(component, &:with_batch_details)
    end

    it "passes the batch to subcomponent" do
      expect(subcomponent).to have_received(:new).with(batch:)
    end
  end

  describe "#error_details" do
    let(:subcomponent) { ::Admin::AppropriateBodies::Batches::ErrorDetailsComponent }

    before do
      allow(subcomponent).to receive(:new).and_call_original
      render_inline(component, &:with_error_details)
    end

    it "passes the batch to subcomponent" do
      expect(subcomponent).to have_received(:new).with(batch:)
    end
  end

  describe "#induction_details" do
    let(:subcomponent) { ::Admin::AppropriateBodies::Batches::InductionDetailsComponent }

    before do
      allow(subcomponent).to receive(:new).and_call_original
      render_inline(component, &:with_induction_details)
    end

    it "passes the batch to subcomponent" do
      expect(subcomponent).to have_received(:new).with(batch:)
    end
  end
end
