RSpec.describe "Appropriate Body teacher extensions index", type: :request do
  include AuthHelper
  let(:appropriate_body) { create(:appropriate_body) }
  let(:teacher) { create(:teacher) }
  let!(:induction_period) { create(:induction_period, :active, teacher:, appropriate_body:) }

  describe 'when not signed in' do
    it 'redirects to the root page' do
      get("/appropriate-body/teachers/#{teacher.id}/extensions")

      expect(response).to be_redirection
      expect(response.redirect_url).to eql(root_url)
    end
  end

  describe 'when signed in as an appropriate body user' do
    let!(:user) { sign_in_as(:appropriate_body_user, appropriate_body:) }

    describe 'GET /appropriate-body/teachers/:id/extensions' do
      it 'displays the extensions list' do
        create(:induction_extension, teacher:, number_of_terms: 2)

        get("/appropriate-body/teachers/#{teacher.id}/extensions")

        expect(response).to be_successful
        expect(response.body).to include('2.0 terms')
      end
    end
  end
end
