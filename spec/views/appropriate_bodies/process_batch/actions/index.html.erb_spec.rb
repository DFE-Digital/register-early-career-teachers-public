RSpec.describe "appropriate_bodies/process_batch/actions/index.html.erb" do
  let(:pending_induction_submission_batches) do
    [
      FactoryBot.create(:pending_induction_submission_batch, :action, :completed),
      FactoryBot.create(:pending_induction_submission_batch, :action, :processed),
      FactoryBot.create(:pending_induction_submission_batch, :action, :processing)
    ]
  end

  before do
    assign(:pending_induction_submission_batches, pending_induction_submission_batches)
    render
  end

  it 'has links' do
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: ab_teachers_path)
    expect(rendered).to have_link('Go back to homepage', href: ab_teachers_path)
    expect(rendered).to have_link('Upload a CSV', href: new_ab_batch_action_path)
  end

  it 'has a heading' do
    expect(view.content_for(:page_title)).to eql('Overview for recording outcomes using a CSV')
  end

  it 'lists outcomes in a table' do
    expect(rendered).to have_selector('table tr', count: 4)
    expect(rendered).to have_selector('th', text: 'Reference')
    expect(rendered).to have_selector('th', text: 'File name')
    expect(rendered).to have_selector('th', text: 'Status')
    expect(rendered).to have_selector('th', text: 'Action')

    expect(rendered).to have_selector('td', text: 'completed')
    expect(rendered).to have_selector('td', text: 'processed')
    expect(rendered).to have_selector('td', text: 'processing')
  end
end
