RSpec.describe "Viewing the appropriate bodies index", type: :request do
  describe "GET /admin/appropriate-bodies" do
    it "redirects to sign in path" do
      get "/admin/organisations/appropriate-bodies"
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get "/admin/organisations/appropriate-bodies"

        expect(response.status).to eq(401)
      end
    end

    context "with an authenticated DfE user" do
      include_context "sign in as DfE user"

      let!(:appropriate_body_period_1) { FactoryBot.create(:appropriate_body_period, name: "Captain Scrummy") }
      let!(:appropriate_body_period_2) { FactoryBot.create(:appropriate_body_period, name: "Captain Hook") }

      it "display appropriate bodies" do
        get "/admin/organisations/appropriate-bodies"

        expect(response.status).to eq(200)
        expect(response.body).to include("Captain Scrummy", "Captain Hook")
      end

      it "omits de-designated appropriate bodies" do
        FactoryBot.create(:appropriate_body_period, :inactive, name: "Captain Retired")

        get "/admin/organisations/appropriate-bodies"

        expect(response.status).to eq(200)
        expect(response.body).not_to include("Captain Retired")
      end

      it "includes de-designated appropriate bodies when asked for" do
        FactoryBot.create(:appropriate_body_period, :inactive, name: "Captain Retired")

        get "/admin/organisations/appropriate-bodies?include_de_designated=1"

        expect(response.status).to eq(200)
        expect(response.body).to include("Captain Retired", "Captain Hook", "Captain Scrummy")
      end

      it "shows 20 appropriate bodies per page" do
        20.times { |i| FactoryBot.create(:appropriate_body_period, name: "Admiral Ackbar #{i}") }

        get "/admin/organisations/appropriate-bodies"

        expect(response.status).to eq(200)
        expect(response.body).not_to include("Captain Hook")
        expect(response.body).not_to include("Captain Scrummy")

        get "/admin/organisations/appropriate-bodies?page=2"

        expect(response.status).to eq(200)
        expect(response.body).to include("Captain Hook", "Captain Scrummy")
      end

      context "when searching for appropriate bodies" do
        it "displays search results" do
          get "/admin/organisations/appropriate-bodies?q=Hook"
          expect(response.status).to eq(200)

          expect(response.body).to include("Captain Hook")
          expect(response.body).not_to include("Captain Scrummy")
        end

        it "omits de-designated appropriate bodies" do
          FactoryBot.create(:appropriate_body_period, :inactive, name: "Captain Hooked")

          get "/admin/organisations/appropriate-bodies?q=Hook"

          expect(response.status).to eq(200)
          expect(response.body).to include("Captain Hook")
          expect(response.body).not_to include("Captain Hooked")
        end

        it "includes de-designated appropriate bodies when asked for" do
          FactoryBot.create(:appropriate_body_period, :inactive, name: "Captain Hooked")

          get "/admin/organisations/appropriate-bodies?q=Hook&include_de_designated=1"

          expect(response.status).to eq(200)
          expect(response.body).to include("Captain Hook", "Captain Hooked")
          expect(response.body).not_to include("Captain Scrummy")
        end

        it "keeps filtering by the search term on later pages" do
          25.times { |i| FactoryBot.create(:appropriate_body_period, name: "Captain Hook #{i}") }

          get "/admin/organisations/appropriate-bodies?q=Hook&page=2"

          expect(response.status).to eq(200)
          expect(response.body).to include("Captain Hook")
          expect(response.body).not_to include("Captain Scrummy")
        end
      end
    end
  end
end
