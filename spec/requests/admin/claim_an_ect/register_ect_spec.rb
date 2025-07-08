RSpec.describe 'Admin claiming an ECT: registering the ECT' do
  let(:trs_qts_awarded_on) { 3.years.ago.to_date }
  let!(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let!(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission, trs_qts_awarded_on:, appropriate_body: appropriate_body) }
  let(:page_heading) { "Add induction period for" }
  let(:pending_induction_submission_id_param) { pending_induction_submission.id.to_s }

  describe 'GET /admin/appropriate_bodies/:appropriate_body_id/claim-an-ect/register-ect/:id/edit' do
    context 'when not signed in' do
      it 'redirects to sign in path' do
        get("/admin/appropriate_bodies/#{appropriate_body.id}/claim-an-ect/register-ect/#{pending_induction_submission.id}/edit")

        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "with an authenticated non-DfE user" do
      include_context 'sign in as non-DfE user'

      it "requires authorisation" do
        get("/admin/appropriate_bodies/#{appropriate_body.id}/claim-an-ect/register-ect/#{pending_induction_submission.id}/edit")
        expect(response.status).to eq(401)
      end
    end

    context "with an authenticated DfE user" do
      include_context 'sign in as DfE user'

      it 'finds the right PendingInductionSubmission record and renders the page' do
        get("/admin/appropriate_bodies/#{appropriate_body.id}/claim-an-ect/register-ect/#{pending_induction_submission.id}/edit")

        expect(response.body).to include(%(<form action="/admin/appropriate_bodies/#{appropriate_body.id}/claim-an-ect/register-ect/#{pending_induction_submission.id}?method=patch"))
        expect(response).to be_successful
      end
    end
  end

  describe 'PATCH /admin/appropriate_bodies/:appropriate_body_id/claim-an-ect/register-ect/:id' do
    context 'when not signed in' do
      it 'redirects to sign in path' do
        patch("/admin/appropriate_bodies/#{appropriate_body.id}/claim-an-ect/register-ect/#{pending_induction_submission.id}")

        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "with an authenticated non-DfE user" do
      include_context 'sign in as non-DfE user'

      it "requires authorisation" do
        patch("/admin/appropriate_bodies/#{appropriate_body.id}/claim-an-ect/register-ect/#{pending_induction_submission.id}")
        expect(response.status).to eq(401)
      end
    end

    context "with an authenticated DfE user" do
      include_context 'sign in as DfE user'

      before { allow(Admin::ClaimAnECT::RegisterECT).to receive(:new).with(any_args).and_call_original }

      context "when the submission is valid" do
        let(:registration_params) do
          {
            started_on: "2023-09-01",
            finished_on: "2024-08-01",
            induction_programme: "fip",
            trs_induction_status: "Passed",
            appropriate_body_id: appropriate_body.id,
            number_of_terms: "6"
          }
        end

        it 'passes the parameters to the Admin::ClaimAnECT::RegisterECT service and redirects' do
          patch(
            "/admin/appropriate_bodies/#{appropriate_body.id}/claim-an-ect/register-ect/#{pending_induction_submission.id}",
            params: { pending_induction_submission: registration_params }
          )

          expect(Admin::ClaimAnECT::RegisterECT).to have_received(:new).with(
            pending_induction_submission:,
            author: anything
          )

          expect(response).to be_redirection
          expect(response.redirect_url).to match(%r{/admin/appropriate_bodies/#{appropriate_body.id}/claim-an-ect/register-ect/\d+\z})
        end
      end

      context "when the submission is invalid" do
        let(:invalid_params) do
          {
            started_on: "",
            induction_programme: "",
            trs_induction_status: "",
            appropriate_body_id: "",
            number_of_terms: ""
          }
        end

        it 're-renders the edit page with errors' do
          patch(
            "/admin/appropriate_bodies/#{appropriate_body.id}/claim-an-ect/register-ect/#{pending_induction_submission.id}",
            params: { pending_induction_submission: invalid_params }
          )

          expect(response.status).to eq(200)
          expect(response.body).to include(page_heading)
        end
      end
    end
  end

  describe 'GET /admin/appropriate_bodies/:appropriate_body_id/claim-an-ect/register-ect/:id' do
    context 'when not signed in' do
      it 'redirects to sign in path' do
        get("/admin/appropriate_bodies/#{appropriate_body.id}/claim-an-ect/register-ect/#{pending_induction_submission.id}")

        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "with an authenticated non-DfE user" do
      include_context 'sign in as non-DfE user'

      it "requires authorisation" do
        get("/admin/appropriate_bodies/#{appropriate_body.id}/claim-an-ect/register-ect/#{pending_induction_submission.id}")
        expect(response.status).to eq(401)
      end
    end

    context "with an authenticated DfE user" do
      include_context 'sign in as DfE user'

      it 'finds the right PendingInductionSubmission record and renders the page' do
        get("/admin/appropriate_bodies/#{appropriate_body.id}/claim-an-ect/register-ect/#{pending_induction_submission.id}/")

        expect(response.body).to include(pending_induction_submission.trs_first_name)
        expect(response.body).to include(pending_induction_submission.trs_last_name)
        expect(response.body).to include("successfully imported")
        expect(response).to be_successful
      end
    end
  end
end
