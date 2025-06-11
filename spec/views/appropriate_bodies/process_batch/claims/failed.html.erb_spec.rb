RSpec.describe "appropriate_bodies/process_batch/claims/_failed.html.erb" do
  let(:pending_induction_submission_batch) { FactoryBot.create(:pending_induction_submission_batch, :claim, :failed) }

  before do
    assign(:pending_induction_submission_batch, pending_induction_submission_batch)

    render
  end

  it 'links back to bulk claims overview' do
    expect(rendered).to have_text("You'll need to try again")
    expect(rendered).to have_link('Go back to your overview', href: ab_batch_claims_path)
  end
end
