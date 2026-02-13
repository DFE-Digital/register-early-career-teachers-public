RSpec.describe "AppropriateBodies::UnclaimedController", type: :request do
  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period) }

  describe "GET /appropriate-body/schools-data" do
    context "when not signed in" do
      it "redirects to the root page" do
        get("/appropriate-body/schools-data")
        expect(response).to redirect_to(root_url)
      end
    end

    context "when signed in as an appropriate body user" do
      let!(:user) { sign_in_as(:appropriate_body_user, appropriate_body: appropriate_body_period) }

      it "returns a successful response" do
        get("/appropriate-body/schools-data")
        expect(response).to be_successful
      end

      it "displays the page title" do
        get("/appropriate-body/schools-data")
        expect(response.body).to include("ECT induction records to review")
      end

      it "renders the detailed review section component" do
        get("/appropriate-body/schools-data")
        expect(response.body).to include("This is live data")
      end
    end
  end
end
