RSpec.describe Admin::AppropriateBodies::BulkUploadComponent, type: :component do
  subject(:component) { described_class.new(batch:) }

  let(:batch) do
    FactoryBot.create(:pending_induction_submission_batch, :claim, :completed)
  end

  describe "#batch_details" do
    before do
      allow(::Admin::AppropriateBodies::Batches::BatchDetailsComponent).to receive(:new).and_call_original
      render_inline(component, &:with_batch_details)
    end

    it "passes the batch to slot component" do
      expect(::Admin::AppropriateBodies::Batches::BatchDetailsComponent).to have_received(:new).with(batch:)
    end
  end

  describe "#error_details" do
    before do
      allow(::Admin::AppropriateBodies::Batches::ErrorDetailsComponent).to receive(:new).and_call_original
      render_inline(component, &:with_error_details)
    end

    it "passes the batch to slot component" do
      expect(::Admin::AppropriateBodies::Batches::ErrorDetailsComponent).to have_received(:new).with(batch:)
    end
  end

  describe "#induction_details" do
    before do
      allow(::Admin::AppropriateBodies::Batches::InductionDetailsComponent).to receive(:new).and_call_original
      render_inline(component, &:with_induction_details)
    end

    it "passes the batch to slot component" do
      expect(::Admin::AppropriateBodies::Batches::InductionDetailsComponent).to have_received(:new).with(batch:)
    end
  end
end
