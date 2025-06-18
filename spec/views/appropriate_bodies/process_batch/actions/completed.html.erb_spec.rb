RSpec.describe "appropriate_bodies/process_batch/actions/_completed.html.erb" do
  let(:pending_induction_submission_batch) { FactoryBot.create(:pending_induction_submission_batch, :action, :completed) }

  before do
    render locals: { batch: pending_induction_submission_batch }
  end

  it 'sets the page title' do
    expect(view.content_for(:page_title)).to eql('Outcomes successfully recorded')
  end

  it 'links back to bulk actions overview' do
    expect(rendered).to have_link('Go back to your overview', href: ab_batch_actions_path)
  end

  it 'links back to homepage' do
    expect(rendered).to have_link('Go back to your homepage', href: ab_teachers_path)
  end
end
