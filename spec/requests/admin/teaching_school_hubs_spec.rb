RSpec.describe "Admin::TeachingSchoolHubsController", type: :request do
  let(:teaching_school_hub) do
    FactoryBot.create(:appropriate_body, name: "Hub Name")
  end

  before do
    urn = teaching_school_hub.dfe_sign_in_organisation.urn
    name = teaching_school_hub.dfe_sign_in_organisation.name
    gias_school = FactoryBot.create(:gias_school, :eligible_type, :in_england, name:, urn:)
    FactoryBot.create(:school, :eligible, urn:, gias_school:)

    FactoryBot.create(:region, districts: %w[West East], appropriate_body: teaching_school_hub)
    FactoryBot.create(:region, districts: %w[North], appropriate_body: teaching_school_hub)
  end

  describe "GET /index" do
    context "when signed in as admin" do
      include_context "sign in as DfE user"

      it "returns http success" do
        get "/admin/organisations/teaching-school-hubs"
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Hub Name")
      end
    end

    context "when signed in as a non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get "/admin/organisations/teaching-school-hubs"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        get "/admin/organisations/teaching-school-hubs"
        expect(response).to redirect_to("/sign-in")
      end
    end
  end

  describe "GET /show" do
    context "when signed in as admin" do
      include_context "sign in as DfE user"

      it "returns http success" do
        get "/admin/organisations/teaching-school-hubs/#{teaching_school_hub.id}"
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Hub Name")
        expect(response.body).to include("West, East, and North")
      end
    end

    context "when signed in as a non-DfE user" do
      include_context "sign in as non-DfE user"

      it "requires authorisation" do
        get "/admin/organisations/teaching-school-hubs/#{teaching_school_hub.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        get "/admin/organisations/teaching-school-hubs/#{teaching_school_hub.id}"
        expect(response).to redirect_to("/sign-in")
      end
    end
  end
end
