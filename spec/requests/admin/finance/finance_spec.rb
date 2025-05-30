RSpec.describe "Admin finance page", type: :request do
  describe "GET /admin/finance" do
    it "redirects to sign in path" do
      get "/admin/finance"
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context 'sign in as non-DfE user'

      it "requires authorisation" do
        get "/admin/finance"
        expect(response.status).to eq(401)
      end
    end

    context 'when signed in as a DfE user' do
      include_context 'sign in as DfE user'

      it 'displays the finance page' do
        get "/admin/finance"

        expect(response.status).to eq(200)
      end
    end
  end
end
