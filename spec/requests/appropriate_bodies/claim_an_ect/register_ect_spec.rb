RSpec.describe 'Appropriate body claiming an ECT: registering the ECT' do
  let(:trs_qts_awarded_on) { 3.years.ago.to_date }
  let!(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let!(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission, appropriate_body:, trs_qts_awarded_on:) }
  let(:page_heading) { "Tell us about" }
  let(:pending_induction_submission_id_param) { pending_induction_submission.id.to_s }

  describe 'GET /appropriate-body/claim-an-ect/register-ect/:id/edit' do
    context 'when not signed in' do
      it 'redirects to the root page' do
        get("/appropriate-body/claim-an-ect/register-ect/#{pending_induction_submission.id}/edit")

        expect(response).to redirect_to(root_url)
      end
    end

    context 'when signed in as an appropriate body user' do
      before { sign_in_as(:appropriate_body_user, appropriate_body:) }

      it 'searches within the scope of the current appropriate body' do
        allow(PendingInductionSubmissions::Search).to receive(:new).with(appropriate_body:).and_call_original
        get("/appropriate-body/claim-an-ect/register-ect/#{pending_induction_submission.id}/edit")
        expect(PendingInductionSubmissions::Search).to have_received(:new).with(appropriate_body:).once
      end

      it 'finds the right PendingInductionSubmission record and renders the page' do
        get("/appropriate-body/claim-an-ect/register-ect/#{pending_induction_submission.id}/edit")
        expect(response.body).to include(%(<form action="/appropriate-body/claim-an-ect/register-ect/#{pending_induction_submission.id}?method=patch"))
        expect(response).to be_successful
      end
    end
  end

  describe 'POST /appropriate-body/claim-an-ect/register-ect/:id' do
    context 'when not signed in' do
      it 'redirects to the root page' do
        patch("/appropriate-body/claim-an-ect/register-ect/#{pending_induction_submission.id}")

        expect(response).to redirect_to(root_url)
      end
    end

    context 'when signed in' do
      let(:author_first_name) { 'Anette' }
      let(:author_last_name) { 'Benning' }
      let(:author_email) { 'ab@something.com' }
      let!(:user) { sign_in_as(:appropriate_body_user, appropriate_body:, method: :dfe_sign_in, first_name: author_first_name, last_name: author_last_name, email: author_email) }

      before { allow(AppropriateBodies::ClaimAnECT::RegisterECT).to receive(:new).with(any_args).and_call_original }

      context 'when the submission is valid' do
        let(:start_date) { trs_qts_awarded_on + 1.year }
        let(:registration_params) do
          {
            trs_induction_status: 'None',
            induction_programme: 'fip',
            'started_on(3)' => start_date.day.to_s,
            'started_on(2)' => start_date.month.to_s,
            'started_on(1)' => start_date.year.to_s
          }
        end

        before do
          allow_any_instance_of(AppropriateBodies::ClaimAnECT::RegisterECT).to receive(:register).and_call_original
        end

        it 'searches within the scope of the current appropriate body' do
          allow(PendingInductionSubmissions::Search).to receive(:new).with(appropriate_body:).and_call_original
          patch(
            "/appropriate-body/claim-an-ect/register-ect/#{pending_induction_submission.id}",
            params: { pending_induction_submission: registration_params }
          )
          expect(PendingInductionSubmissions::Search).to have_received(:new).with(appropriate_body:).once
        end

        it 'passes the parameters to the AppropriateBodies::ClaimAnECT::RegisterECT service and redirects' do
          patch(
            "/appropriate-body/claim-an-ect/register-ect/#{pending_induction_submission.id}",
            params: { pending_induction_submission: registration_params }
          )

          expect(AppropriateBodies::ClaimAnECT::RegisterECT).to have_received(:new).with(
            appropriate_body:,
            pending_induction_submission:,
            author: instance_of(Sessions::Users::AppropriateBodyUser)
          ) do |arguments|
            arguments.fetch(:author).tap do |author|
              expect(author.name).to eql(user.name)
              expect(author.email).to eql(user.email)
            end
          end

          expect(response).to redirect_to(%r{/claim-an-ect/register-ect/\d+\z})
        end

        it 'calls AppropriateBodies::ClaimAnECT::RegisterECT#register' do
          fake_register_ect = double(AppropriateBodies::ClaimAnECT::RegisterECT, register: pending_induction_submission, pending_induction_submission:)
          allow(AppropriateBodies::ClaimAnECT::RegisterECT).to receive(:new).and_return(fake_register_ect)

          patch(
            "/appropriate-body/claim-an-ect/register-ect/#{pending_induction_submission.id}",
            params: { pending_induction_submission: registration_params }
          )

          expect(fake_register_ect).to have_received(:register).with(
            ActionController::Parameters.new(**registration_params).permit!
          ).once
        end

        context "with new induction programme types (post-2025)" do
          let(:registration_params) do
            {
              trs_induction_status: 'None',
              training_programme: 'provider_led',
              'started_on(3)' => start_date.day.to_s,
              'started_on(2)' => start_date.month.to_s,
              'started_on(1)' => start_date.year.to_s
            }
          end

          it 'passes the parameters to the AppropriateBodies::ClaimAnECT::RegisterECT service and redirects' do
            patch(
              "/appropriate-body/claim-an-ect/register-ect/#{pending_induction_submission.id}",
              params: { pending_induction_submission: registration_params }
            )

            expect(AppropriateBodies::ClaimAnECT::RegisterECT).to have_received(:new).with(
              appropriate_body:,
              pending_induction_submission:,
              author: instance_of(Sessions::Users::AppropriateBodyUser)
            ) do |arguments|
              arguments.fetch(:author).tap do |author|
                expect(author.name).to eql(user.name)
                expect(author.email).to eql(user.email)
              end
            end

            expect(response).to redirect_to(%r{/claim-an-ect/register-ect/\d+\z})
          end
        end
      end

      context "when the submission is invalid" do
        context "with new induction programme types (post-2025)" do
          let(:registration_params) { { training_programme: "xyz", } }

          it 'passes the parameters to the AppropriateBodies::ClaimAnECT::RegisterECT but does not redirect and rerenders the form' do
            patch(
              "/appropriate-body/claim-an-ect/register-ect/#{pending_induction_submission.id}",
              params: { pending_induction_submission: registration_params }
            )

            expect(response).to be_ok
            expect(response.body).to include(page_heading)
          end
        end
      end
    end
  end

  describe 'GET /appropriate-body/claim-an-ect/register-ect/:id' do
    context 'when not signed in' do
      it 'redirects to the root page' do
        get("/appropriate-body/claim-an-ect/register-ect/#{pending_induction_submission.id}")

        expect(response).to redirect_to(root_url)
      end
    end

    context 'when signed in' do
      before { sign_in_as(:appropriate_body_user, appropriate_body:) }

      it 'searches within the scope of the current appropriate body' do
        allow(PendingInductionSubmissions::Search).to receive(:new).with(appropriate_body:).and_call_original
        get("/appropriate-body/claim-an-ect/register-ect/#{pending_induction_submission.id}/")
        expect(PendingInductionSubmissions::Search).to have_received(:new).with(appropriate_body:).once
      end

      it 'finds the right PendingInductionSubmission record and renders the page' do
        get("/appropriate-body/claim-an-ect/register-ect/#{pending_induction_submission.id}/")

        expect(response.body).to include(pending_induction_submission.trs_first_name)
        expect(response.body).to include(pending_induction_submission.trs_last_name)
        expect(response.body).to include("successfully claimed")
        expect(response).to be_successful
      end
    end
  end
end
