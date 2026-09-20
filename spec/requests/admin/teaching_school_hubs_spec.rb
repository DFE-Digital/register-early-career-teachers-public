RSpec.describe "Admin::TeachingSchoolHubsController", type: :request do
  let(:teaching_school_hub) { FactoryBot.create(:teaching_school_hub) }
  let(:provisioning_lead_school) { FactoryBot.create(:school, :eligible) }
  let(:lead_school) { FactoryBot.create(:school, :eligible) }

  let(:appropriate_body) do
    FactoryBot.create(:appropriate_body_period, :teaching_school_hub,
                      teaching_school_hub:,
                      provisioning_school: provisioning_lead_school,
                      name: teaching_school_hub.name)
  end

  before do
    region_1 = FactoryBot.create(:region, code: "R1", districts: %w[West East])
    region_2 = FactoryBot.create(:region, code: "R2", districts: %w[North])
    region_3 = FactoryBot.create(:region, code: "R3", districts: %w[South])

    FactoryBot.create(:teaching_school_hub_lead_school,
                      appropriate_body:,
                      region: region_1,
                      school: provisioning_lead_school)
    FactoryBot.create(:teaching_school_hub_lead_school,
                      appropriate_body:,
                      region: region_2,
                      school: lead_school)
    FactoryBot.create(:teaching_school_hub_lead_school,
                      appropriate_body:,
                      region: region_3,
                      school: lead_school)
  end

  describe "GET /index" do
    context "when signed in as admin" do
      include_context "sign in as DfE user"

      it "returns http success" do
        get "/admin/organisations/teaching-school-hubs"
        expect(response).to have_http_status(:success)
        expect(response.body).to include(appropriate_body.name)
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
        expect(response.body).to include(appropriate_body.name)
        expect(response.body).to include(provisioning_lead_school.name)
        expect(response.body).to include(lead_school.name)
        expect(response.body).to include("West and East")
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
