RSpec.describe Admin::AppropriateBodies::Batches::BatchDetailsComponent, type: :component do
  subject(:component) { described_class.new(batch:) }

  let(:batch) do
    FactoryBot.create(:pending_induction_submission_batch, :claim, :completed)
  end

  before do
    render_inline(component)
  end

  it "renders content" do
    expect(rendered_content).to have_text("File name")
    expect(rendered_content).to have_text("Submitted")
    expect(rendered_content).to have_text("Completed")
    expect(rendered_content).to have_text("Status")
  end
end
