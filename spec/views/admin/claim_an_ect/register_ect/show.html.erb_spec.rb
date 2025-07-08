RSpec.describe 'admin/claim_an_ect/register_ect/show', type: :view do
  let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission) }

  before do
    assign(:pending_induction_submission, pending_induction_submission)
  end

  it 'renders the success panel' do
    render

    expect(rendered).to have_css('.govuk-panel')
    expect(rendered).to have_text("You've successfully imported")
    expect(rendered).to have_text(pending_induction_submission.trs_first_name)
    expect(rendered).to have_text(pending_induction_submission.trs_last_name)
    expect(rendered).to have_text("record from TRS")
  end

  it 'renders the success message' do
    render

    expect(rendered).to have_text("You've successfully imported")
    expect(rendered).to have_text("into the system")
    expect(rendered).to have_text("their induction period has been created")
  end

  it 'renders the what happens next section' do
    render

    expect(rendered).to have_text('What happens next')
    expect(rendered).to have_text("You can now manage")
    expect(rendered).to have_text("induction using this service")
  end

  it 'renders the list of actions' do
    render

    expect(rendered).to have_text('view and edit their induction periods')
    expect(rendered).to have_text('record outcomes')
    expect(rendered).to have_text('add extensions')
    expect(rendered).to have_text('view their timeline')
  end

  it 'renders the back to teachers link' do
    render

    expect(rendered).to have_link('Back to teachers', href: admin_teachers_path)
  end

  it 'renders the view teacher link' do
    render

    expect(rendered).to have_text('View teacher record')
  end
end
