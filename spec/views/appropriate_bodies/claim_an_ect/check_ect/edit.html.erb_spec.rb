RSpec.describe 'appropriate_bodies/claim_an_ect/check_ect/edit.html.erb' do
  let(:appropriate_body) { create(:appropriate_body) }

  let(:pending_induction_submission) do
    create(:pending_induction_submission, appropriate_body:, trs_first_name: 'Anna', trs_last_name: 'Chancellor')
  end

  let(:teacher) do
    create(:teacher,
           trs_first_name: pending_induction_submission.trs_first_name,
           trs_last_name: pending_induction_submission.trs_last_name,
           trn: pending_induction_submission.trn)
  end

  before do
    assign(:teacher, teacher)
    assign(:pending_induction_submission, pending_induction_submission)
  end

  it "sets the page title to 'Check details for <name>'" do
    render
    expected_title = "Check details for Anna Chancellor"
    expect(sanitize(view.content_for(:page_title))).to eql(sanitize(expected_title))
  end

  it 'includes a back button that links to the AB homepage' do
    render
    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: '/appropriate-body/claim-an-ect/find-ect/new')
  end

  describe 'claim induction CTA' do
    context 'when the ECT is not yet claimed by an appropriate body' do
      it 'renders the claim button' do
        render
        expect(rendered).to have_button('Claim induction')
      end
    end

    context 'when the ECT has an ongoing induction period with another appropriate body' do
      let!(:induction_period) { create(:induction_period, :active, teacher:) }

      before { assign(:current_appropriate_body, appropriate_body) }

      it 'replaces the claim button with explanatory text' do
        render
        expect(rendered).to have_text('You cannot register Anna Chancellor')
        expect(rendered).to have_text('completing their induction with another appropriate body')
        expect(rendered).not_to have_button('Claim induction')
      end
    end
  end

  describe 'induction status' do
    let(:teacher) { nil }
    let(:pending_induction_submission) { create(:pending_induction_submission, trs_induction_status: 'FailedInWales') }

    it 'displays the status tag that corresponds to the TRS induction status on the pending induction submission' do
      render
      expect(rendered).to have_css('strong.govuk-tag', text: 'Failed in Wales')
    end
  end

  describe 'induction periods' do
    context 'when the ECT has past induction periods' do
      let!(:current_induction_period) { create(:induction_period, :active, teacher:) }

      it 'shows the current induction period' do
        render
        expect(rendered).to have_css('.govuk-summary-card__title', text: current_induction_period.appropriate_body.name)
      end

      it 'has no release link' do
        render
        expect(rendered).not_to have_link('Release')
      end
    end

    context 'when the ECT has past induction periods' do
      let!(:past_induction_period) { create(:induction_period, teacher:) }

      it 'shows a list of past induction periods' do
        render
        expect(rendered).to have_css('ul.govuk-list > li .govuk-summary-card__title', text: past_induction_period.appropriate_body.name)
      end
    end
  end

  describe 'extensions' do
    context 'with no extensions but with a teacher' do
      it 'does not display the row' do
        render
        expect(rendered).not_to have_css('.govuk-summary-list__key', text: 'Extensions')
        expect(rendered).not_to have_css('.govuk-summary-list__value', text: '0.0')
      end
    end

    context 'with no extensions and no teacher' do
      let(:teacher) { nil }

      it 'does not display the row' do
        render
        expect(rendered).not_to have_css('.govuk-summary-list__key', text: 'Extensions')
        expect(rendered).not_to have_css('.govuk-summary-list__value', text: '0.0')
      end
    end

    context 'with extensions and teacher' do
      let!(:extension) { create(:induction_extension, teacher:) }

      it 'displays the row' do
        render
        expect(rendered).to have_css('.govuk-summary-list__key', text: 'Extensions')
        expect(rendered).to have_css('.govuk-summary-list__value', text: '1.2 terms')
      end
    end
  end
end
