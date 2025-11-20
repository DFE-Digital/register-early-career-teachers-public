RSpec.describe Admin::AppropriateBodies::Batches::BatchCardsComponent, type: :component do
  subject(:component) { described_class.new(batch:) }

  let(:batch) do
    FactoryBot.create(:pending_induction_submission_batch, :claim, :completed,
                      errored_count: 2,
                      uploaded_count: 4)
  end

  before do
    render_inline(component)
  end

  it "renders content" do
    expect(rendered_content).to have_text("50.0%")
    expect(rendered_content).to have_text("error rate")
    expect(rendered_content).to have_text("rows completed")
  end
end
