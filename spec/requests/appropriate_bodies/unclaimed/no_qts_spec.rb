RSpec.describe "AppropriateBodies::Unclaimed::NoQtsController", type: :request do
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  describe "GET /appropriate-body/schools-data/no-qts" do
    context "when not signed in" do
      it "redirects to the root page" do
        get("/appropriate-body/schools-data/no-qts")
        expect(response).to redirect_to(root_url)
      end
    end

    context "when signed in as an appropriate body user" do
      let!(:user) { sign_in_as(:appropriate_body_user, appropriate_body:) }

      it "returns a successful response" do
        get("/appropriate-body/schools-data/no-qts")
        expect(response).to be_successful
      end

      it "displays the page title" do
        get("/appropriate-body/schools-data/no-qts")
        expect(response.body).to include("ECTs without qualified teacher status (QTS)")
      end
    end
  end
end
