RSpec.describe "appropriate_bodies/claim_an_ect/check_ect/edit.html.erb" do
  let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission, trs_first_name: 'Anna', trs_last_name: 'Chancellor') }

  it "sets the page title to 'Check details for <name>'" do
    assign(:pending_induction_submission, pending_induction_submission)

    render

    expected_title = "Check details for Anna Chancellor"
    expect(sanitize(view.content_for(:page_title))).to eql(sanitize(expected_title))
  end

  it 'includes a back button that links to the AB homepage' do
    assign(:pending_induction_submission, pending_induction_submission)

    render

    expect(view.content_for(:backlink_or_breadcrumb)).to have_link('Back', href: '/appropriate-body/claim-an-ect/find-ect/new')
  end

  describe 'induction periods' do
    let(:teacher) { FactoryBot.create(:teacher) }
    let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission) }

    context 'when the ECT has past induction periods' do
      let!(:current_induction_period) { FactoryBot.create(:induction_period, :active, teacher:) }

      it 'shows the current induction period' do
        assign(:teacher, teacher)
        assign(:pending_induction_submission, pending_induction_submission)

        render

        expect(rendered).to have_css('.govuk-summary-card__title', text: current_induction_period.appropriate_body.name)
      end

      it 'has no release link' do
        assign(:teacher, teacher)
        assign(:pending_induction_submission, pending_induction_submission)

        render

        expect(rendered).not_to have_link('Release')
      end
    end

    context 'when the ECT has past induction periods' do
      let!(:past_induction_period) { FactoryBot.create(:induction_period, teacher:) }

      it 'shows a list of past induction periods' do
        assign(:teacher, teacher)
        assign(:pending_induction_submission, pending_induction_submission)

        render

        expect(rendered).to have_css('ul.govuk-list > li .govuk-summary-card__title', text: past_induction_period.appropriate_body.name)
      end
    end
  end
end
