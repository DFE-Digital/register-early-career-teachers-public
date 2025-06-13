RSpec.describe "appropriate_bodies/process_batch/claims/new.html.erb" do
  let(:pending_induction_submission_batch) { FactoryBot.build(:pending_induction_submission_batch) }

  before do
    assign(:pending_induction_submission_batch, pending_induction_submission_batch)

    render
  end

  it 'renders a form' do
    expect(rendered).to have_css('form')
  end

  it 'links to the template file' do
    expect(rendered).to have_link('download a CSV template', href: '/bulk-claims-template.csv')
    expect(rendered).to have_text('Your file needs to look like this example')
  end

  it 'has a file field for the CSV' do
    expect(rendered).to have_css('label', text: 'Upload a file')
  end
end
