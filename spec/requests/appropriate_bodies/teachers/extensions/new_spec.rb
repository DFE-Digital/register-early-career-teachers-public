RSpec.describe "Appropriate Body teacher extensions new", type: :request do
  include AuthHelper
  let(:appropriate_body) { create(:appropriate_body) }
  let(:teacher) { create(:teacher) }
  let!(:induction_period) { create(:induction_period, :active, teacher:, appropriate_body:) }
  let!(:user) { sign_in_as(:appropriate_body_user, appropriate_body:) }

  describe 'GET /appropriate-body/teachers/:id/extensions/new' do
    it 'displays the new extension form' do
      get("/appropriate-body/teachers/#{teacher.id}/extensions/new")

      expect(response).to be_successful
      expect(response.body).to include('FTE terms')
    end
  end

  describe 'POST /appropriate-body/teachers/:id/extensions' do
    context 'with valid parameters' do
      let(:valid_params) { { induction_extension: { number_of_terms: 1.5 } } }

      it 'creates a new extension' do
        expect {
          post("/appropriate-body/teachers/#{teacher.id}/extensions", params: valid_params)
        }.to change(InductionExtension, :count).by(1)

        expect(response).to redirect_to(ab_teacher_path(teacher))
        follow_redirect!
        expect(response.body).to include('Extension was successfully added')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) { { induction_extension: { number_of_terms: 17 } } }

      it 'does not create an extension' do
        expect {
          post("/appropriate-body/teachers/#{teacher.id}/extensions", params: invalid_params)
        }.not_to change(InductionExtension, :count)

        expect(response).to be_unprocessable
      end
    end
  end
end
