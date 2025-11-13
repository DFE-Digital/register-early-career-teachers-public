RSpec.describe "Appropriate Body bulk actions index page", type: :request do
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  describe 'GET /appropriate-body/bulk/actions' do
    context 'when not signed in' do
      it 'redirects to the root page' do
        get("/appropriate-body/bulk/actions")
        expect(response).to redirect_to(root_url)
      end
    end

    context 'when signed in as an appropriate body user' do
      it 'renders the page successfully' do
        sign_in_as(:appropriate_body_user, appropriate_body:)
        get("/appropriate-body/bulk/actions")
        expect(response).to be_successful
      end
    end
  end
end
