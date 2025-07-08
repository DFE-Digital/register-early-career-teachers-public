RSpec.describe 'admin/claim_an_ect/find_ect/new', type: :view do
  let(:pending_induction_submission) { FactoryBot.build(:pending_induction_submission) }

  before do
    assign(:pending_induction_submission, pending_induction_submission)
  end

  it 'renders the page heading' do
    render

    expect(rendered).to have_text("Find an early career teacher")
  end

  it 'renders the TRN field' do
    render

    expect(rendered).to have_field('Teacher reference number (TRN)')
    expect(rendered).to have_text('Must be 7 digits long')
  end

  it 'renders the date of birth field' do
    render

    expect(rendered).to have_text('Date of birth')
  end

  it 'renders the submit button' do
    render

    expect(rendered).to have_button('Save and continue')
  end

  it 'renders the form with the correct action' do
    render

    expect(rendered).to have_css('form[action="/admin/claim-an-ect/find-ect"]')
  end

  context 'when there are errors' do
    before do
      pending_induction_submission.errors.add(:trn, 'is required')
      pending_induction_submission.errors.add(:date_of_birth, 'is required')
    end

    it 'renders the error summary' do
      render

      expect(rendered).to have_css('.govuk-error-summary')
      expect(rendered).to have_text('is required')
    end
  end
end
