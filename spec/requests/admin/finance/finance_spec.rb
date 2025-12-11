RSpec.describe "Admin finance page", type: :request do
  describe "GET /admin/finance" do
    it "redirects to sign in path when not signed in" do
      get "/admin/finance"
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "returns unauthorised" do
        get "/admin/finance"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a non-finance DfE user" do
      include_context "sign in as DfE user"

      it "returns unauthorised with the finance access error message" do
        get "/admin/finance"

        expect(response).to have_http_status(:unauthorized)

        expect(response.body).to include(
          "This is to access financial information for Register early career teachers. To gain access, contact the product team."
        )
      end
    end

    context "when signed in as a finance DfE user" do
      before do
        sign_in_as(:dfe_user, user: FactoryBot.create(:user, :finance))
      end

      it "displays the finance page" do
        get "/admin/finance"
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
