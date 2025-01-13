require "rails_helper"

RSpec.describe "Admin root", type: :request do
  describe "GET /admin" do
    it "redirects to sign-in" do
      get "/admin"
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context 'sign in as non-DfE user'

      it "requires authorisation" do
        get "/admin"
        expect(response.status).to eq(401)
      end
    end

    context "with an authenticated DfE user" do
      include_context 'sign in as DfE user'

      it "shows the teachers search page" do
        get "/admin"
        expect(response.status).to eq(200)

        expect(response.body).to include("Early career teachers")
        expect(response.body).to include("Search by name or TRN")
      end
    end
  end
end
