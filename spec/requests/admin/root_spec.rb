require "rails_helper"

RSpec.describe "Admin root", type: :request do
  describe "GET /admin" do
    it "redirects to sign-in" do
      get "/admin"
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      before do
        sign_in_as(:appropriate_body_user, appropriate_body: FactoryBot.create(:appropriate_body))
      end

      it "requires authorisation" do
        get "/admin"
        expect(response.status).to eq(401)
      end
    end

    context "with an authenticated DfE user" do
      before do
        sign_in_as(:dfe_user, user: FactoryBot.create(:user, :admin))
      end

      it "shows the teachers search page" do
        get "/admin"
        expect(response.status).to eq(200)

        expect(response.body).to include("Early career teachers")
        expect(response.body).to include("Search by name or TRN")
      end
    end
  end
end
