RSpec.describe 'Appropriate body releasing an ECT' do
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:teacher) { FactoryBot.create(:teacher) }

  describe 'GET /appropriate-body/teachers/:id/release/new' do
    context 'when not signed in' do
      it 'redirects to the root page' do
        get("/appropriate-body/teachers/#{teacher.id}/release/new")

        expect(response).to be_redirection
        expect(response.redirect_url).to eql(root_url)
      end
    end

    context 'when signed in as an appropriate body user' do
      let!(:user) { sign_in_as(:appropriate_body_user, appropriate_body:) }

      context 'and a teacher actively training' do
        before do
          FactoryBot.create(:induction_period, :active, appropriate_body:, teacher:)
        end

        it 'instantiates a new PendingInductionSubmission and renders the page' do
          allow(PendingInductionSubmission).to receive(:new).and_call_original

          get("/appropriate-body/teachers/#{teacher.id}/release/new")

          expect(response).to be_successful
          expect(PendingInductionSubmission).to have_received(:new).once
        end
      end
    end
  end

  describe 'POST /appropriate-body/teachers/:id/release' do
    context 'when not signed in' do
      it 'redirects to the root page' do
        post("/appropriate-body/teachers/#{teacher.id}/release")

        expect(response).to be_redirection
        expect(response.redirect_url).to eql(root_url)
      end
    end

    context 'when signed in as an appropriate body user' do
      let!(:user) { sign_in_as(:appropriate_body_user, appropriate_body:) }

      before do
        allow(AppropriateBodies::ReleaseECT).to receive(:new).and_call_original
      end

      context "when the teacher has one ongoing induction period" do
        before do
          allow(PendingInductionSubmissions::Build).to receive(:closing_induction_period).and_call_original
        end

        let!(:induction_period) do
          FactoryBot.create(:induction_period, :active, appropriate_body:, teacher:, started_on: "2022-09-01")
        end

        let(:release_params) do
          {
            pending_induction_submission: {
              finished_on: "2023-07-31",
              number_of_terms: 6
            }
          }
        end

        it 'uses PendingInductionSubmissions::Build to instantiate the PendingInductionSubmission' do
          post(
            "/appropriate-body/teachers/#{teacher.id}/release",
            params: release_params
          )

          expect(PendingInductionSubmissions::Build).to have_received(:closing_induction_period).once
        end

        it 'updates the induction period and redirects to show page' do
          post(
            "/appropriate-body/teachers/#{teacher.id}/release",
            params: release_params
          )

          induction_period.reload
          expect(induction_period.finished_on).to eq(Date.parse("2023-07-31"))
          expect(induction_period.number_of_terms).to eq(6)

          expect(response).to be_redirection
          expect(response.redirect_url).to end_with("/appropriate-body/teachers/#{teacher.id}/release")
        end

        context 'with missing params' do
          let(:invalid_params) do
            {
              pending_induction_submission: {
                finished_on: nil,
                number_of_terms: nil
              }
            }
          end

          it 'renders the new form with errors' do
            post(
              "/appropriate-body/teachers/#{teacher.id}/release",
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
                number_of_terms: 5
              }
            }
          end

          it 'includes finish date must be later than start date' do
            post(
              "/appropriate-body/teachers/#{teacher.id}/release",
              params: invalid_params
            )

            expect(response.body).to include('The finish date must be later than the start date')
          end
        end
      end
    end
  end
end
