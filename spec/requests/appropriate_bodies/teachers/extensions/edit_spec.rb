RSpec.describe "Appropriate Body teacher extensions edit", type: :request do
  include AuthHelper
  include ActionView::Helpers::SanitizeHelper

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:teacher) { FactoryBot.create(:teacher) }
  let!(:induction_period) { FactoryBot.create(:induction_period, :active, teacher:, appropriate_body:) }
  let!(:user) { sign_in_as(:appropriate_body_user, appropriate_body:) }
  let(:extension) { FactoryBot.create(:induction_extension, teacher:, number_of_terms: 2) }

  describe 'GET /appropriate-body/teachers/:teacher_id/extensions/:id/edit' do
    it 'displays the edit extension form' do
      get("/appropriate-body/teachers/#{teacher.id}/extensions/#{extension.id}/edit")

      expect(response).to be_successful
      expect(sanitize(response.body)).to include("Edit #{Teachers::Name.new(teacher).full_name}'s extension")
      expect(response.body).to include('2.0')
    end
  end

  describe 'PATCH /appropriate-body/teachers/:teacher_id/extensions/:id' do
    context 'with valid parameters' do
      let(:valid_params) { { induction_extension: { number_of_terms: 3 } } }

      it 'updates the extension' do
        patch("/appropriate-body/teachers/#{teacher.id}/extensions/#{extension.id}", params: valid_params)

        expect(response).to redirect_to(ab_teacher_path(teacher))
        follow_redirect!
        expect(response.body).to include('Extension was successfully updated')
        expect(extension.reload.number_of_terms).to eq(3)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) { { induction_extension: { number_of_terms: 17 } } }

      it 'does not update the extension' do
        patch("/appropriate-body/teachers/#{teacher.id}/extensions/#{extension.id}", params: invalid_params)

        expect(response).to be_unprocessable
        expect(extension.reload.number_of_terms).to eq(2)
      end
    end
  end
end
