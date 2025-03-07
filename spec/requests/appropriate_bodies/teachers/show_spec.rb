RSpec.describe "Appropriate Body teacher show page", type: :request do
  include AuthHelper
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:teacher) { FactoryBot.create(:teacher) }
  let!(:induction_period) { FactoryBot.create(:induction_period, :active, teacher:, appropriate_body:) }

  describe 'GET /appropriate-body/teachers/:id' do
    context 'when not signed in' do
      it 'redirects to the root page' do
        get("/appropriate-body/teachers/#{teacher.id}")

        expect(response).to be_redirection
        expect(response.redirect_url).to eql(root_url)
      end
    end

    context 'when signed in as an appropriate body user' do
      let!(:user) { sign_in_as(:appropriate_body_user, appropriate_body:) }

      it 'displays the teacher details' do
        get("/appropriate-body/teachers/#{teacher.id}")

        expect(response).to be_successful
        expect(response.body).to include(teacher.trs_first_name)
        expect(response.body).to include(teacher.trs_last_name)
      end

      context 'when the teacher does not exist' do
        it 'returns a 404 error' do
          get("/appropriate-body/teachers/999999999")
          expect(response).to have_http_status(:not_found)
        end
      end

      context 'when the teacher is not associated with the appropriate body' do
        let(:other_appropriate_body) { FactoryBot.create(:appropriate_body) }
        let(:other_teacher) { FactoryBot.create(:teacher) }

        # Create an induction period that is finished and has no outcome
        # This won't be included in current_or_completed_while_at_appropriate_body
        let!(:other_induction_period) do
          FactoryBot.create(:induction_period,
                            teacher: other_teacher,
                            appropriate_body:,
                            started_on: 6.months.ago,
                            finished_on: 1.month.ago,
                            outcome: nil)
        end

        it 'returns a 404 error' do
          get("/appropriate-body/teachers/#{other_teacher.id}")
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
