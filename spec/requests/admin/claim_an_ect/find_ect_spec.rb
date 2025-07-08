RSpec.describe 'Admin claiming an ECT: finding the ECT' do
  include_context 'fake trs api client'

  let(:page_heading) { "Find an early career teacher" }
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  describe 'GET /admin/appropriate_bodies/:appropriate_body_id/claim-an-ect/find-ect/new' do
    context 'when not signed in' do
      it 'redirects to sign in path' do
        get("/admin/appropriate_bodies/#{appropriate_body.id}/claim-an-ect/find-ect/new")

        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "with an authenticated non-DfE user" do
      include_context 'sign in as non-DfE user'

      it "requires authorisation" do
        get("/admin/appropriate_bodies/#{appropriate_body.id}/claim-an-ect/find-ect/new")
        expect(response.status).to eq(401)
      end
    end

    context "with an authenticated DfE user" do
      include_context 'sign in as DfE user'

      it 'instantiates a new PendingInductionSubmission and renders the page' do
        allow(PendingInductionSubmission).to receive(:new).and_call_original

        get("/admin/appropriate_bodies/#{appropriate_body.id}/claim-an-ect/find-ect/new")

        expect(response.body).to include(page_heading)
        expect(PendingInductionSubmission).to have_received(:new).once
        expect(response).to be_successful
      end
    end
  end

  describe 'POST /admin/appropriate_bodies/:appropriate_body_id/claim-an-ect/find-ect' do
    let(:trn) { '1234567' }
    let(:birth_year_param) { "1990" }
    let(:birth_month_param) { "12" }
    let(:birth_day_param) { "25" }

    let(:search_params) do
      {
        trn:,
        "date_of_birth(3i)" => birth_day_param,
        "date_of_birth(2i)" => birth_month_param,
        "date_of_birth(1i)" => birth_year_param
      }
    end

    context 'when not signed in' do
      it 'redirects to sign in path' do
        post("/admin/appropriate_bodies/#{appropriate_body.id}/claim-an-ect/find-ect", params: { pending_induction_submission: search_params })

        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "with an authenticated non-DfE user" do
      include_context 'sign in as non-DfE user'

      it "requires authorisation" do
        post("/admin/appropriate_bodies/#{appropriate_body.id}/claim-an-ect/find-ect", params: { pending_induction_submission: search_params })
        expect(response.status).to eq(401)
      end
    end

    context "with an authenticated DfE user" do
      include_context 'sign in as DfE user'

      context "when the submission is valid and finds a teacher" do
        it 'passes the parameters to the Admin::ClaimAnECT::FindECT service and redirects' do
          post("/admin/appropriate_bodies/#{appropriate_body.id}/claim-an-ect/find-ect", params: { pending_induction_submission: search_params })

          last_pending_induction_submission_id = PendingInductionSubmission.last.id

          expect(response.redirect_url).to end_with("/admin/appropriate_bodies/#{appropriate_body.id}/claim-an-ect/check-ect/#{last_pending_induction_submission_id}/edit")
        end
      end

      context "when the submission is valid but ECT was prohibited from teaching" do
        include_context 'fake trs api client that finds teacher prohibited from teaching'

        it 're-renders the find page and displays the relevant error' do
          post("/admin/appropriate_bodies/#{appropriate_body.id}/claim-an-ect/find-ect", params: { pending_induction_submission: search_params })

          expect(response.redirect_url).to match(%r{/admin/appropriate_bodies/#{appropriate_body.id}/claim-an-ect/errors/prohibited-from-teaching/\d+\z})
        end
      end

      context "when the submission is valid but ECT already exists in the system" do
        let!(:teacher) { FactoryBot.create(:teacher, trn:) }

        it 'redirects to the teacher page with a notice' do
          post("/admin/appropriate_bodies/#{appropriate_body.id}/claim-an-ect/find-ect", params: { pending_induction_submission: search_params })

          expect(response).to be_redirection
          expect(response.redirect_url).to match(%r{/admin/teachers/\d+\z})
          expect(flash[:notice]).to include("Teacher #{teacher.trs_first_name} #{teacher.trs_last_name} already exists in the system")
        end
      end

      context "when the submission is valid but no ECT is found" do
        include_context 'fake trs api client that finds nothing'
        let(:birth_year_param) { "2001" }

        it 're-renders the find page and displays the relevant error' do
          post("/admin/appropriate_bodies/#{appropriate_body.id}/claim-an-ect/find-ect", params: { pending_induction_submission: search_params })

          expect(response).to be_ok
          expect(response.body).to include(page_heading)
          expect(response.body).to include(/No teacher with this TRN and date of birth was found/)
        end
      end
    end
  end
end
