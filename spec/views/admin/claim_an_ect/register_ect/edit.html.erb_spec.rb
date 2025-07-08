RSpec.describe 'admin/claim_an_ect/register_ect/edit', type: :view do
  let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission) }
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:appropriate_bodies) { [appropriate_body] }

  before do
    assign(:pending_induction_submission, pending_induction_submission)
    assign(:appropriate_bodies, appropriate_bodies)
  end

  it 'renders the page heading' do
    render

    expect(rendered).to have_text("Add induction period for")
    expect(rendered).to have_text(pending_induction_submission.trs_first_name)
    expect(rendered).to have_text(pending_induction_submission.trs_last_name)
  end

  it 'renders the form with the correct action' do
    render

    expect(rendered).to have_css("form[action='/admin/claim-an-ect/register-ect/#{pending_induction_submission.id}?method=patch']")
  end

  it 'renders the appropriate body selection field' do
    render

    expect(rendered).to have_text('Appropriate body')
    expect(rendered).to have_text("Select the appropriate body responsible for this ECT's induction")
    expect(rendered).to have_select('pending_induction_submission[appropriate_body_id]')
  end

  it 'renders the induction start date field' do
    render

    expect(rendered).to have_text('Induction start date')
    expect(rendered).to have_text("This is the date the ECT started their induction")
  end

  it 'renders the induction programme field' do
    render

    expect(rendered).to have_text('Induction programme')
    expect(rendered).to have_radio_button('pending_induction_submission[induction_programme]', value: 'fip')
    expect(rendered).to have_radio_button('pending_induction_submission[induction_programme]', value: 'cip')
    expect(rendered).to have_radio_button('pending_induction_submission[induction_programme]', value: 'diy')
  end

  it 'renders the number of terms field' do
    render

    expect(rendered).to have_text('Number of terms')
    expect(rendered).to have_text("Expected number of terms for the ECT to complete their induction")
    expect(rendered).to have_select('pending_induction_submission[number_of_terms]')
  end

  it 'renders the submit button' do
    render

    expect(rendered).to have_button('Save and continue')
  end

  context 'when there are errors' do
    before do
      pending_induction_submission.errors.add(:appropriate_body_id, 'is required')
      pending_induction_submission.errors.add(:started_on, 'is required')
    end

    it 'renders the error summary' do
      render

      expect(rendered).to have_css('.govuk-error-summary')
      expect(rendered).to have_text('is required')
    end
  end
end
