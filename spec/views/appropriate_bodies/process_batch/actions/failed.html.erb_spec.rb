RSpec.describe "appropriate_bodies/process_batch/actions/_failed.html.erb" do
  let(:pending_induction_submission_batch) { FactoryBot.create(:pending_induction_submission_batch, :action, :failed) }

  before do
    assign(:pending_induction_submission_batch, pending_induction_submission_batch)

    render
  end

  it 'sets the page title' do
    expect(view.content_for(:page_title)).to eql('Something went wrong')
  end

  it 'links back to bulk actions overview' do
    expect(rendered).to have_text("You'll need to try again")
    expect(rendered).to have_link('Go back to your overview', href: ab_batch_actions_path)
  end
end
