RSpec.describe 'Appropriate body recording a failed outcome for a teacher' do
  let!(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let!(:teacher) { FactoryBot.create(:teacher) }
  let!(:induction_period) do
    FactoryBot.create(
      :induction_period,
      :active,
      teacher:,
      appropriate_body:,
      started_on: 1.month.ago,
      induction_programme: 'fip'
    )
  end
  let(:valid_params) do
    {
      pending_induction_submission: {
        finished_on: Date.current,
        number_of_terms: 3,
        outcome: 'fail'
      }
    }
  end

  describe 'GET /appropriate-body/teachers/:id/record-failed-outcome/new' do
    context 'when not signed in' do
      it 'redirects to the signin page' do
        get("/appropriate-body/teachers/#{teacher.id}/record-failed-outcome/new")

        expect(response).to be_redirection
        expect(response.redirect_url).to end_with('/sign-in')
      end
    end

    context 'when signed in as an appropriate body user' do
      before { sign_in_as(:appropriate_body_user, appropriate_body:) }

      it 'renders the new form for a valid teacher' do
        get("/appropriate-body/teachers/#{teacher.id}/record-failed-outcome/new")

        expect(response).to be_successful
        expect(response.body).to include('Record failed outcome')
      end

      it 'returns not found for an invalid teacher' do
        get("/appropriate-body/teachers/invalid-trn/record-failed-outcome/new")

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /appropriate-body/teachers/:id/record-failed-outcome' do
    context 'when not signed in' do
      it 'redirects to the signin page' do
        post("/appropriate-body/teachers/#{teacher.id}/record-failed-outcome")

        expect(response).to be_redirection
        expect(response.redirect_url).to end_with('/sign-in')
      end
    end

    context 'when signed in as an appropriate body user' do
      let!(:user) { sign_in_as(:appropriate_body_user, appropriate_body:) }

      context 'with valid params' do
        let(:fake_record_outcome) { double(AppropriateBodies::RecordOutcome, fail!: true) }

        before do
          allow(AppropriateBodies::RecordOutcome).to receive(:new).and_return(fake_record_outcome)
          allow(PendingInductionSubmissions::Build).to receive(:closing_induction_period).and_call_original
        end

        it 'creates a new pending induction submission' do
          expect {
            post(
              "/appropriate-body/teachers/#{teacher.id}/record-failed-outcome",
              params: valid_params
            )
          }.to change(PendingInductionSubmission, :count).by(1)
        end

        it 'uses PendingInductionSubmissions::Build to instantiate the PendingInductionSubmission' do
          post(
            "/appropriate-body/teachers/#{teacher.id}/record-failed-outcome",
            params: valid_params
          )

          expect(PendingInductionSubmissions::Build).to have_received(:closing_induction_period).once
        end

        it 'calls the record outcome service and redirects' do
          post(
            "/appropriate-body/teachers/#{teacher.id}/record-failed-outcome",
            params: valid_params
          )

          expect(AppropriateBodies::RecordOutcome).to have_received(:new).with(
            appropriate_body:,
            pending_induction_submission: an_instance_of(PendingInductionSubmission),
            teacher:,
            author: an_instance_of(Sessions::Users::AppropriateBodyPersona)
          )

          expect(response).to be_redirection
          expect(response.redirect_url).to end_with("/appropriate-body/teachers/#{teacher.id}/record-failed-outcome")
        end
      end

      context 'with missing params' do
        let(:invalid_params) do
          {
            pending_induction_submission: {
              finished_on: nil,
              number_of_terms: nil,
              outcome: 'fail'
            }
          }
        end

        it 'renders the new form with errors' do
          post(
            "/appropriate-body/teachers/#{teacher.id}/record-failed-outcome",
            params: invalid_params
          )

          expect(response.body).to include('There is a problem')
        end
      end

      context 'when finished_on is before started_on' do
        let(:invalid_params) do
          {
            pending_induction_submission: {
              finished_on: induction_period.started_on - 1.month,
              number_of_terms: 5,
              outcome: 'fail'
            }
          }
        end

        it 'includes finish date must be later than start date' do
          post(
            "/appropriate-body/teachers/#{teacher.id}/record-failed-outcome",
            params: invalid_params
          )

          expect(response.body).to include('The finish date must be later than the start date')
        end
      end
    end
  end

  describe 'GET /appropriate-body/teachers/:id/record-failed-outcome' do
    let!(:induction_period) do
      FactoryBot.create(
        :induction_period,
        :fail,
        teacher:,
        appropriate_body:,
        induction_programme: 'fip'
      )
    end

    context 'when not signed in' do
      it 'redirects to the signin page' do
        get("/appropriate-body/teachers/#{teacher.id}/record-failed-outcome")

        expect(response).to be_redirection
        expect(response.redirect_url).to end_with('/sign-in')
      end
    end

    context 'when signed in as an appropriate body user' do
      before { sign_in_as(:appropriate_body_user, appropriate_body:) }

      it 'renders the show page for a valid teacher' do
        get("/appropriate-body/teachers/#{teacher.id}/record-failed-outcome")

        expect(response).to be_successful
      end
    end
  end
end
