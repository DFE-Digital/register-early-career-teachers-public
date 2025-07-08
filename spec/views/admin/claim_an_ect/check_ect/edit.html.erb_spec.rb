RSpec.describe 'admin/claim_an_ect/check_ect/edit', type: :view do
  let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission) }
  let(:teacher) { nil }

  before do
    assign(:pending_induction_submission, pending_induction_submission)
    assign(:teacher, teacher)
  end

  it 'renders the page heading' do
    render

    expect(rendered).to have_text("Check details for")
    expect(rendered).to have_text(pending_induction_submission.trs_first_name)
    expect(rendered).to have_text(pending_induction_submission.trs_last_name)
  end

  it 'renders the TRN' do
    render

    expect(rendered).to have_text("TRN: #{pending_induction_submission.trn}")
  end

  it 'renders the personal details section' do
    render

    expect(rendered).to have_text('Personal details')
    expect(rendered).to have_text(pending_induction_submission.trs_first_name)
    expect(rendered).to have_text(pending_induction_submission.trs_last_name)
    expect(rendered).to have_text(pending_induction_submission.trs_date_of_birth.strftime('%d %B %Y'))
    expect(rendered).to have_text(pending_induction_submission.trs_email_address)
  end

  it 'renders the qualification details section' do
    render

    expect(rendered).to have_text('Qualification details')
    expect(rendered).to have_text('Initial teacher training (ITT) provider')
    expect(rendered).to have_text('Qualified teacher status (QTS)')
  end

  it 'renders the admin claim ECT actions component' do
    render

    expect(rendered).to have_css('form')
    expect(rendered).to have_button('Import ECT')
  end

  context 'when there are TRS alerts' do
    let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission, trs_alerts: %w[alert1 alert2]) }

    it 'renders the alerts section' do
      render

      expect(rendered).to have_text('Check a teacher')
      expect(rendered).to have_text('Use the Check a teacher')
    end
  end

  context 'when there are no TRS alerts' do
    let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission, trs_alerts: []) }

    it 'does not render the alerts section' do
      render

      expect(rendered).not_to have_text('Check a teacher')
    end
  end
end
