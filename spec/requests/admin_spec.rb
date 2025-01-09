RSpec.describe "Admin", type: :request do
  describe "GET /admin" do
    it "redirects to sign-in" do
      get "/admin"
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated user" do
      before do
        sign_in_as(:appropriate_body_user, appropriate_body: FactoryBot.create(:appropriate_body))
      end

      context "when the user isn't a DfE user" do
        it "requires authorisation" do
          get "/admin"

          expect(response.status).to eq(401)
        end
      end

      context 'when the user is a DfE user' do
        before do
          sign_in_as(:dfe_user, user: FactoryBot.create(:user, :admin))
        end

        it "allows access to DfE users" do
          get "/admin"
          expect(response.status).to eq(200)
        end
      end
    end
  end
end
