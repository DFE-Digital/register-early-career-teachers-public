RSpec.describe "appropriate_bodies/process_batch/claims/_processing.html.erb" do
  let(:pending_induction_submission_batch) do
    create(:pending_induction_submission_batch, :claim, :processing)
  end

  before do
    render locals: { batch: pending_induction_submission_batch }
  end

  it 'displays progress indicator' do
    expect(rendered).to have_text("We're processing your CSV file, it could take up to 5 minutes.")
    expect(rendered).to have_text("If you leave this page, you can come back to it from your overview.")
    expect(rendered).to have_text("0%")
  end
end
