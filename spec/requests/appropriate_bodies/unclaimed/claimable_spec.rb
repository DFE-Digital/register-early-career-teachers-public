RSpec.describe "AppropriateBodies::Unclaimed::ClaimableController", type: :request do
  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period) }

  describe "GET /appropriate-body/schools-data/claimable" do
    context "when not signed in" do
      it "redirects to the root page" do
        get("/appropriate-body/schools-data/claimable")
        expect(response).to redirect_to(root_url)
      end
    end

    context "when signed in as an appropriate body user" do
      let!(:user) { sign_in_as(:appropriate_body_user, appropriate_body: appropriate_body_period) }

      it "returns a successful response" do
        get("/appropriate-body/schools-data/claimable")
        expect(response).to be_successful
      end

      it "displays the page title" do
        get("/appropriate-body/schools-data/claimable")
        expect(response.body).to include("Check and claim an ECT induction")
      end
    end
  end
end
