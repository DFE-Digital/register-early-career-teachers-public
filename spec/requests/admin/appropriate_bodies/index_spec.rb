RSpec.describe "Viewing the appropriate bodies index", type: :request do
  describe "GET /admin/appropriate-bodies" do
    it "redirects to sign in path" do
      get "/admin/organisations/appropriate-bodies"
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context 'sign in as non-DfE user'

      it "requires authorisation" do
        get "/admin/organisations/appropriate-bodies"

        expect(response.status).to eq(401)
      end
    end

    context "with an authenticated DfE user" do
      include_context 'sign in as DfE user'

      let!(:appropriate_body1) { FactoryBot.create(:appropriate_body, name: "Captain Scrummy") }
      let!(:appropriate_body2) { FactoryBot.create(:appropriate_body, name: "Captain Hook") }

      it "display appropriate bodies" do
        get "/admin/organisations/appropriate-bodies"

        expect(response.status).to eq(200)
        expect(response.body).to include("Captain Scrummy", "Captain Hook")
      end

      context "when searching for appropriate bodies" do
        it "displays search results" do
          get "/admin/organisations/appropriate-bodies?q=Hook"
          expect(response.status).to eq(200)

          expect(response.body).to include("Captain Hook")
          expect(response.body).not_to include("Captain Scrummy")
        end
      end
    end
  end
end
