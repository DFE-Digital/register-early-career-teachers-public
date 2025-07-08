RSpec.describe 'Admin claiming an ECT: checking we have the right ECT' do
  let(:page_heading) { "Check details for" }
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let!(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission, appropriate_body: appropriate_body) }
  let(:pending_induction_submission_id_param) { pending_induction_submission.id.to_s }

  describe 'GET /admin/appropriate_bodies/:appropriate_body_id/claim-an-ect/check-ect/:id/edit' do
    context 'when not signed in' do
      it 'redirects to sign in path' do
        get("/admin/appropriate_bodies/#{appropriate_body.id}/claim-an-ect/check-ect/#{pending_induction_submission.id}/edit")

        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "with an authenticated non-DfE user" do
      include_context 'sign in as non-DfE user'

      it "requires authorisation" do
        get("/admin/appropriate_bodies/#{appropriate_body.id}/claim-an-ect/check-ect/#{pending_induction_submission.id}/edit")
        expect(response.status).to eq(401)
      end
    end

    context "with an authenticated DfE user" do
      include_context 'sign in as DfE user'

      it 'finds the right PendingInductionSubmission record and renders the page' do
        get("/admin/appropriate_bodies/#{appropriate_body.id}/claim-an-ect/check-ect/#{pending_induction_submission.id}/edit")

        expect(response).to be_successful
      end

      context 'when alerts are present' do
        let!(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission, appropriate_body: appropriate_body, trs_alerts: %w[some alerts]) }

        it 'includes info about the check a teachers record service' do
          get("/admin/appropriate_bodies/#{appropriate_body.id}/claim-an-ect/check-ect/#{pending_induction_submission.id}/edit")

          expect(response.parsed_body.at_css('.govuk-summary-list').text).to include(/Use the Check a teacher.s record service to get more information/)
        end
      end
    end
  end

  describe 'PATCH /admin/appropriate_bodies/:appropriate_body_id/claim-an-ect/check-ect/:id' do
    context 'when not signed in' do
      it 'redirects to sign in path' do
        patch("/admin/appropriate_bodies/#{appropriate_body.id}/claim-an-ect/check-ect/#{pending_induction_submission.id}")

        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "with an authenticated non-DfE user" do
      include_context 'sign in as non-DfE user'

      it "requires authorisation" do
        patch("/admin/appropriate_bodies/#{appropriate_body.id}/claim-an-ect/check-ect/#{pending_induction_submission.id}")
        expect(response.status).to eq(401)
      end
    end

    context "with an authenticated DfE user" do
      include_context 'sign in as DfE user'

      before { allow(Admin::ClaimAnECT::CheckECT).to receive(:new).with(any_args).and_call_original }

      context "when the submission is valid" do
        let(:confirmation_param) { { confirmed: "1", } }

        it 'passes the parameters to the Admin::ClaimAnECT::CheckECT service and redirects' do
          patch(
            "/admin/appropriate_bodies/#{appropriate_body.id}/claim-an-ect/check-ect/#{pending_induction_submission.id}",
            params: { pending_induction_submission: confirmation_param }
          )

          expect(Admin::ClaimAnECT::CheckECT).to have_received(:new).with(
            pending_induction_submission:
          )

          expect(response).to be_redirection
          expect(response.redirect_url).to match(%r{/admin/appropriate_bodies/#{appropriate_body.id}/claim-an-ect/register-ect/\d+/edit\z})
        end
      end

      context "when the ECT has an ongoing induction period with another appropriate body" do
        let!(:preexisting_teacher) { FactoryBot.create(:teacher, trn: pending_induction_submission.trn) }
        let!(:induction_period) { FactoryBot.create(:induction_period, :active, teacher: preexisting_teacher) }

        it 'redirects to the ECT already claimed by another AB early exit page' do
          patch(
            "/admin/appropriate_bodies/#{appropriate_body.id}/claim-an-ect/check-ect/#{pending_induction_submission.id}",
            params: { pending_induction_submission: { confirmed: '1' } }
          )

          redirect_url = "/admin/appropriate_bodies/#{appropriate_body.id}/claim-an-ect/errors/induction-with-another-appropriate-body/#{pending_induction_submission.id}"

          expect(response).to redirect_to(redirect_url)
        end
      end
    end
  end
end
