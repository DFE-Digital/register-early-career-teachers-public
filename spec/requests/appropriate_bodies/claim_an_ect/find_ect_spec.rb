RSpec.describe "Appropriate body claiming an ECT: finding the ECT" do
  include_context "test trs api client"
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  let(:page_heading) { "Find an early career teacher" }

  describe "GET /appropriate-body/claim-an-ect/find-ect" do
    context "when not signed in" do
      it "redirects to the root page" do
        get("/appropriate-body/claim-an-ect/find-ect/new")
        expect(response).to redirect_to(root_url)
      end
    end

    context "when signed in as an appropriate body user" do
      let!(:user) { sign_in_as(:appropriate_body_user, appropriate_body:) }

      it "instantiates a new PendingInductionSubmission and renders the page" do
        allow(PendingInductionSubmission).to receive(:new).and_call_original

        get("/appropriate-body/claim-an-ect/find-ect/new")

        expect(response.body).to include(page_heading)
        expect(PendingInductionSubmission).to have_received(:new).once
        expect(response).to be_successful
      end
    end
  end

  describe "POST /appropriate-body/claim-an-ect/find-ect" do
    context "when not signed in" do
      it "redirects to the root page" do
        post("/appropriate-body/claim-an-ect/find-ect")
        expect(response).to redirect_to(root_url)
      end
    end

    context "when signed in" do
      let!(:user) { sign_in_as(:appropriate_body_user, appropriate_body:) }
      let(:birth_year_param) { "2001" }
      let(:trn) { "1234567" }
      let(:pending_induction_submission) { PendingInductionSubmission.last }

      let(:search_params) do
        {
          :trn => trn,
          "date_of_birth(3)" => "3",
          "date_of_birth(2)" => "5",
          "date_of_birth(1)" => birth_year_param
        }
      end

      before do
        allow(AppropriateBodies::ClaimAnECT::FindECT).to receive(:new).with(any_args).and_call_original
        post("/appropriate-body/claim-an-ect/find-ect", params: {pending_induction_submission: search_params})
      end

      it "passes the parameters to the AppropriateBodies::ClaimAnECT::FindECT service and redirects" do
        expect(AppropriateBodies::ClaimAnECT::FindECT).to have_received(:new).with(appropriate_body:, pending_induction_submission:)
        expect(response).to redirect_to("/appropriate-body/claim-an-ect/check-ect/#{pending_induction_submission.id}/edit")
      end

      context "when the teacher has an ongoing induction" do
        let(:teacher) { FactoryBot.create(:teacher, trn:, trs_first_name: "Trent", trs_last_name: "Reznor") }

        context "with another AB" do
          let!(:induction_period) do
            FactoryBot.create(:induction_period, :ongoing, teacher:, started_on: Date.parse("2 October 2022"))
          end

          before do
            post("/appropriate-body/claim-an-ect/find-ect", params: {pending_induction_submission: search_params})
          end

          it "redirects to the check details page" do
            expect(response).to be_redirection
            expect(response).to redirect_to("/appropriate-body/claim-an-ect/check-ect/#{pending_induction_submission.id}/edit")
            follow_redirect!
            expect(response.body).to include(/Kirk Van Houten is completing their induction with another appropriate body/)
          end
        end

        context "with the current AB" do
          let!(:induction_period) do
            FactoryBot.create(:induction_period, :ongoing, appropriate_body:, teacher:, started_on: Date.parse("2 October 2022"))
          end

          before do
            post("/appropriate-body/claim-an-ect/find-ect", params: {pending_induction_submission: search_params})
          end

          it "redirects to the teacher page" do
            expect(response).to be_redirection
            expect(response).to redirect_to("/appropriate-body/teachers/#{teacher.id}")

            expect(flash[:notice]).to eq("Teacher Trent Reznor already has an ongoing induction period with this appropriate body")
          end
        end
      end

      context "when no ECT is found" do
        include_context "test trs api client that finds nothing"

        let(:birth_year_param) { "2001" }

        before do
          post("/appropriate-body/claim-an-ect/find-ect", params: {pending_induction_submission: search_params})
        end

        it do
          expect(response).to be_ok
          expect(response.body).to include(page_heading)
          expect(response.body).to include(/No teacher with this TRN and date of birth was found/)
        end
      end

      context "when the ECT is deactivated" do
        include_context "test trs api client deactivated teacher"

        let(:birth_year_param) { "2001" }

        before do
          post("/appropriate-body/claim-an-ect/find-ect", params: {pending_induction_submission: search_params})
        end

        it do
          expect(response).to be_ok
          expect(response.body).to include(page_heading)
          expect(response.body).to include(/No teacher with this TRN and date of birth was found/)
        end
      end

      context "when the submission is invalid" do
        let(:birth_year_param) { (Date.current.year - 2).to_s }

        before do
          post("/appropriate-body/claim-an-ect/find-ect", params: {pending_induction_submission: search_params})
        end

        it "re-renders the find page" do
          expect(response).to be_ok
          expect(response.body).to include(page_heading)
        end
      end
    end
  end
end
