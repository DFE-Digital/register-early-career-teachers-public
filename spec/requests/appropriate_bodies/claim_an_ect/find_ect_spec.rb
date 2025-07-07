RSpec.describe 'Appropriate body claiming an ECT: finding the ECT' do
  include_context 'fake trs api client'
  let(:appropriate_body) { create(:appropriate_body) }

  let(:page_heading) { "Find an early career teacher" }

  describe 'GET /appropriate-body/claim-an-ect/find-ect' do
    context 'when not signed in' do
      it 'redirects to the root page' do
        get('/appropriate-body/claim-an-ect/find-ect/new')

        expect(response).to be_redirection
        expect(response.redirect_url).to eql(root_url)
      end
    end

    context 'when signed in as an appropriate body user' do
      let!(:user) { sign_in_as(:appropriate_body_user, appropriate_body:) }

      it 'instantiates a new PendingInductionSubmission and renders the page' do
        allow(PendingInductionSubmission).to receive(:new).and_call_original

        get('/appropriate-body/claim-an-ect/find-ect/new')

        expect(response.body).to include(page_heading)
        expect(PendingInductionSubmission).to have_received(:new).once
        expect(response).to be_successful
      end
    end
  end

  describe 'POST /appropriate-body/claim-an-ect/find-ect' do
    context 'when not signed in' do
      it 'redirects to the root page' do
        post('/appropriate-body/claim-an-ect/find-ect')

        expect(response).to be_redirection
        expect(response.redirect_url).to eql(root_url)
      end
    end

    context 'when signed in' do
      before { allow(AppropriateBodies::ClaimAnECT::FindECT).to receive(:new).with(any_args).and_call_original }

      let!(:user) { sign_in_as(:appropriate_body_user, appropriate_body:) }
      let(:birth_year_param) { "2001" }
      let(:trn) { "1234567" }

      let(:search_params) do
        {
          trn:,
          "date_of_birth(3)" => "3",
          "date_of_birth(2)" => "5",
          "date_of_birth(1)" => birth_year_param,
        }
      end

      context "when the submission is valid" do
        it 'passes the parameters to the AppropriateBodies::ClaimAnECT::FindECT service and redirects' do
          post(
            '/appropriate-body/claim-an-ect/find-ect',
            params: { pending_induction_submission: search_params }
          )

          expect(AppropriateBodies::ClaimAnECT::FindECT).to have_received(:new).with(
            appropriate_body:,
            pending_induction_submission: PendingInductionSubmission.last
          )

          expect(response).to be_redirection
          expect(response.redirect_url).to match(%r{/claim-an-ect/check-ect/\d+/edit\z})
        end
      end

      context "when the submission is valid but ECT does not have QTS awarded" do
        include_context 'fake trs api client that finds teacher without QTS'

        it 're-renders the find page and displays the relevant error' do
          post(
            '/appropriate-body/claim-an-ect/find-ect',
            params: { pending_induction_submission: search_params }
          )

          expect(response.redirect_url).to match(%r{/appropriate-body/claim-an-ect/errors/no-qts/\d+\z})
        end
      end

      context "when the submission is valid but ECT was prohibited from teaching" do
        include_context 'fake trs api client that finds teacher prohibited from teaching'

        it 're-renders the find page and displays the relevant error' do
          post(
            '/appropriate-body/claim-an-ect/find-ect',
            params: { pending_induction_submission: search_params }
          )

          expect(response.redirect_url).to match(%r{/appropriate-body/claim-an-ect/errors/prohibited-from-teaching/\d+\z})
        end
      end

      context "when the submission is valid but ECT has an active induction period with another AB" do
        let(:teacher) { create(:teacher, trn:) }
        let!(:induction_period) do
          create(
            :induction_period,
            :active,
            appropriate_body: create(:appropriate_body),
            teacher:,
            started_on: Date.parse("2 October 2022")
          )
        end

        it 'shows the check details page' do
          post(
            '/appropriate-body/claim-an-ect/find-ect',
            params: { pending_induction_submission: search_params }
          )

          last_pending_induction_submission_id = PendingInductionSubmission.last.id

          expect(response.redirect_url).to end_with("/appropriate-body/claim-an-ect/check-ect/#{last_pending_induction_submission_id}/edit")
        end
      end

      context "when the submission is valid but ECT has an active induction period with the current AB" do
        let(:teacher) { create(:teacher, trn:) }
        let!(:pending_induction_submission) { create(:pending_induction_submission, trn: teacher.trn) }
        let!(:induction_period) do
          create(
            :induction_period,
            :active,
            appropriate_body:,
            teacher:,
            started_on: Date.parse("2 October 2022")
          )
        end

        it 'redirects to the teacher page' do
          post(
            '/appropriate-body/claim-an-ect/find-ect',
            params: { pending_induction_submission: search_params }
          )

          expect(response).to be_redirection
          expect(response.redirect_url).to match(%r{/teachers/\d+\z})
          expect(flash[:notice]).to eq("Teacher #{teacher.trs_first_name} #{teacher.trs_last_name} already has an active induction period with this appropriate body")
        end
      end

      context "when the submission is valid but no ECT is found" do
        include_context 'fake trs api client that finds nothing'
        let(:birth_year_param) { "2001" }

        it 're-renders the find page and displays the relevant error' do
          post(
            '/appropriate-body/claim-an-ect/find-ect',
            params: { pending_induction_submission: search_params }
          )

          expect(response).to be_ok
          expect(response.body).to include(page_heading)
          expect(response.body).to include(/No teacher with this TRN and date of birth was found/)
        end
      end

      context "when the submission is valid but the ECT is deactivated" do
        include_context 'fake trs api client deactivated teacher'
        let(:birth_year_param) { "2001" }

        it 're-renders the find page and displays the relevant error' do
          post(
            '/appropriate-body/claim-an-ect/find-ect',
            params: { pending_induction_submission: search_params }
          )

          expect(response).to be_ok
          expect(response.body).to include(page_heading)
          expect(response.body).to include(/No teacher with this TRN and date of birth was found/)
        end
      end

      context "when the submission is invalid" do
        let(:birth_year_param) { (Date.current.year - 2).to_s }

        it 're-renders the find page' do
          post(
            '/appropriate-body/claim-an-ect/find-ect',
            params: { pending_induction_submission: search_params }
          )

          expect(response).to be_ok
          expect(response.body).to include(page_heading)
        end
      end
    end
  end
end
