RSpec.describe 'Appropriate body recording a failed induction outcome for a teacher' do
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:teacher) { FactoryBot.create(:teacher) }

  let!(:induction_period) do
    FactoryBot.create(:induction_period, :ongoing,
                      teacher:,
                      appropriate_body:)
  end

  describe 'GET /appropriate-body/teachers/:id/record-failed-outcome/new' do
    context 'when not signed in' do
      it 'redirects to the root page' do
        get("/appropriate-body/teachers/#{teacher.id}/record-failed-outcome/new")

        expect(response).to redirect_to(root_url)
      end
    end

    context 'when signed in as an appropriate body user' do
      before { sign_in_as(:appropriate_body_user, appropriate_body:) }

      it 'renders' do
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
    let(:params) do
      {
        appropriate_bodies_record_fail: {
          finished_on: Date.current,
          number_of_terms: 3,
        }
      }
    end

    context 'when not signed in' do
      it 'redirects to the root page' do
        post("/appropriate-body/teachers/#{teacher.id}/record-failed-outcome", params:)

        expect(response).to redirect_to(root_url)
      end
    end

    context 'when signed in as an appropriate body user' do
      before do
        sign_in_as(:appropriate_body_user, appropriate_body:)

        post("/appropriate-body/teachers/#{teacher.id}/record-failed-outcome", params:)
      end

      context 'with valid params' do
        it 'fails the induction and redirects' do
          expect(induction_period.reload).to have_attributes(
            outcome: 'fail',
            finished_on: Date.current,
            number_of_terms: 3
          )

          expect(response).to redirect_to("/appropriate-body/teachers/#{teacher.id}/record-failed-outcome")
        end
      end

      context 'with missing params' do
        let(:params) do
          {
            appropriate_bodies_record_fail: {
              finished_on: nil,
              number_of_terms: nil,
            }
          }
        end

        it 'renders errors' do
          expect(response.body).to include('There is a problem')
          expect(response.body).to include('Enter a finish date')
          expect(response.body).to include('Enter a number of terms')
        end
      end

      context 'with invalid params' do
        let(:params) do
          {
            appropriate_bodies_record_fail: {
              finished_on: induction_period.started_on - 1.month,
              number_of_terms: 16.99,
            }
          }
        end

        it 'renders errors' do
          expect(response.body).to include('There is a problem')
          expect(response.body).to include('The end date must be later than the start date')
          expect(response.body).to include('Number of terms must be between 0 and 16')
        end
      end
    end
  end

  describe 'GET /appropriate-body/teachers/:id/record-failed-outcome' do
    context 'when not signed in' do
      it 'redirects to the root page' do
        get("/appropriate-body/teachers/#{teacher.id}/record-failed-outcome")

        expect(response).to redirect_to(root_url)
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
