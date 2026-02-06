RSpec.describe "AppropriateBodies::Unclaimed::ClaimedByAnotherController", type: :request do
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  describe "GET /appropriate-body/schools-data/claimed-by-another-appropriate-body" do
    context "when not signed in" do
      it "redirects to the root page" do
        get("/appropriate-body/schools-data/claimed-by-another-appropriate-body")
        expect(response).to redirect_to(root_url)
      end
    end

    context "when signed in as an appropriate body user" do
      let!(:user) { sign_in_as(:appropriate_body_user, appropriate_body:) }

      it "returns a successful response" do
        get("/appropriate-body/schools-data/claimed-by-another-appropriate-body")
        expect(response).to be_successful
      end

      it "displays the page title" do
        get("/appropriate-body/schools-data/claimed-by-another-appropriate-body")
        expect(response.body).to include("Check ECTs who are currently claimed by another AB")
      end
    end
  end
end
