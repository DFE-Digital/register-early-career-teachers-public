RSpec.describe "appropriate_bodies/process_batch/claims/_completed.html.erb" do
  let(:pending_induction_submission_batch) { create(:pending_induction_submission_batch, :claim, :completed) }

  before do
    render locals: { batch: pending_induction_submission_batch }
  end

  it 'sets the page title' do
    expect(view.content_for(:page_title)).to eql('ECTs successfully claimed')
  end

  it 'links back to bulk claims overview' do
    expect(rendered).to have_link('Go back to your overview', href: ab_batch_claims_path)
  end

  it 'links back to homepage' do
    expect(rendered).to have_link('Go back to your homepage', href: ab_teachers_path)
  end
end
