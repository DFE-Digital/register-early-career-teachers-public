RSpec.describe "appropriate_bodies/process_batch/claims/_processed.html.erb" do
  let(:pending_induction_submission_batch) { create(:pending_induction_submission_batch, :claim, :processed) }

  before do
    render locals: { batch: pending_induction_submission_batch }
  end

  it 'summarises the CSV file' do
    expect(rendered).to have_text("CSV file summary")
    expect(rendered).to have_text("Your CSV named '' has 0 ECTs with errors.")
  end

  it 'links back to bulk claims overview' do
    expect(rendered).to have_link('Go back to your overview', href: ab_batch_claims_path)
  end
end
