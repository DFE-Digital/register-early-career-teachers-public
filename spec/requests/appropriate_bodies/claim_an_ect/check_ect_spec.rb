RSpec.describe 'Appropriate body claiming an ECT: checking we have the right ECT' do
  include AuthHelper
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:page_heading) { "Check details for" }
  let!(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission, appropriate_body:) }
  let(:pending_induction_submission_id_param) { pending_induction_submission.id.to_s }

  describe 'GET /appropriate-body/claim-an-ect/check-ect/:id/edit' do
    context 'when not signed in' do
      it 'redirects to the root page' do
        get("/appropriate-body/claim-an-ect/register-ect/#{pending_induction_submission.id}/edit")

        expect(response).to be_redirection
        expect(response.redirect_url).to eql(root_url)
      end
    end

    context 'when signed in as an appropriate body user' do
      let!(:user) { sign_in_as(:appropriate_body_user, appropriate_body:) }

      it 'finds the right PendingInductionSubmission record and renders the page' do
        allow(PendingInductionSubmissions::Search).to receive(:new).and_call_original

        get("/appropriate-body/claim-an-ect/register-ect/#{pending_induction_submission.id}/edit")

        expect(PendingInductionSubmissions::Search).to have_received(:new).once
        expect(response).to be_successful
      end

      context 'when alerts are present' do
        let!(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission, appropriate_body:, trs_alerts: %w[some alerts]) }

        it 'includes info about the check a teachers record service' do
          get("/appropriate-body/claim-an-ect/check-ect/#{pending_induction_submission.id}/edit")

          expect(response.parsed_body.at_css('.govuk-summary-list').text).to include(/Use the Check a teacher.s record service to get more information/)
        end
      end

      context 'when alerts are absent' do
        let!(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission, appropriate_body:, trs_alerts: %w[]) }

        it 'does not include info about the check a teachers record service' do
          get("/appropriate-body/claim-an-ect/check-ect/#{pending_induction_submission.id}/edit")

          expect(response.parsed_body.at_css('.govuk-summary-list').text).not_to include(/Use the Check a teacher.s record service to get more information/)
        end
      end
    end
  end

  describe 'POST /appropriate-body/claim-an-ect/check-ect/:id' do
    context 'when not signed in' do
      it 'redirects to the root page' do
        patch("/appropriate-body/claim-an-ect/check-ect/#{pending_induction_submission.id}")

        expect(response).to be_redirection
        expect(response.redirect_url).to eql(root_url)
      end
    end

    context 'when signed in' do
      let!(:user) { sign_in_as(:appropriate_body_user, appropriate_body:) }

      before { allow(AppropriateBodies::ClaimAnECT::CheckECT).to receive(:new).with(any_args).and_call_original }

      context "when the submission is valid" do
        let(:confirmation_param) { { confirmed: "1", } }

        it 'passes the parameters to the AppropriateBodies::ClaimAnECT::CheckECT service and redirects' do
          patch(
            "/appropriate-body/claim-an-ect/check-ect/#{pending_induction_submission.id}",
            params: { pending_induction_submission: confirmation_param }
          )

          expect(AppropriateBodies::ClaimAnECT::CheckECT).to have_received(:new).with(
            appropriate_body:,
            pending_induction_submission:
          )

          expect(response).to be_redirection
          expect(response.redirect_url).to match(%r{/claim-an-ect/register-ect/\d+/edit\z})
        end
      end

      context "when the ECT has an ongoing induction period with another appropriate body" do
        let!(:preexisting_teacher) { FactoryBot.create(:teacher, trn: pending_induction_submission.trn) }
        let!(:induction_period) { FactoryBot.create(:induction_period, :active, teacher: preexisting_teacher) }

        it 'redirects to the ECT already claimed by another AB early exit page' do
          patch(
            "/appropriate-body/claim-an-ect/check-ect/#{pending_induction_submission.id}",
            params: { pending_induction_submission: { confirmed: '1' } }
          )

          redirect_url = "/appropriate-body/claim-an-ect/errors/induction-with-another-appropriate-body/#{pending_induction_submission.id}"

          expect(response).to redirect_to(redirect_url)
        end
      end
    end
  end
end
