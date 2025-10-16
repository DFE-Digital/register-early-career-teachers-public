RSpec.describe Admin::AppropriateBodies::Batches::ErrorDetailsComponent, type: :component do
  subject(:component) { described_class.new(batch:) }

  let(:batch) do
    FactoryBot.create(:pending_induction_submission_batch, :claim, :completed, errored_count:)
  end

  before do
    render_inline(component)
  end

  context "without errors" do
    let(:errored_count) { 0 }

    it "does not render content" do
      expect(rendered_content).to be_empty
    end
  end

  context "with errors" do
    let(:errored_count) { 1 }

    it "renders content" do
      expect(rendered_content).not_to be_empty
    end
  end
end
