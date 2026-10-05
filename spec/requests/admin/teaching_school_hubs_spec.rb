RSpec.describe "Admin::TeachingSchoolHubsController", type: :request do
  let(:teaching_school_hub) { FactoryBot.create(:teaching_school_hub) }
  let(:provisioning_lead_school) { FactoryBot.create(:school, :eligible) }
  let(:lead_school) { FactoryBot.create(:school, :eligible) }

  let(:appropriate_body_period) do
    FactoryBot.create(:appropriate_body_period, :teaching_school_hub,
                      teaching_school_hub:,
                      provisioning_school: provisioning_lead_school,
                      name: teaching_school_hub.name)
  end

  before do
    region_1 = FactoryBot.create(:region, code: "R1", districts: %w[West East])
    region_2 = FactoryBot.create(:region, code: "R2", districts: %w[North])
    region_3 = FactoryBot.create(:region, code: "R3", districts: %w[South])

    FactoryBot.create(:region_award,
                      appropriate_body_period:,
                      region: region_1,
                      school: provisioning_lead_school)
    FactoryBot.create(:region_award,
                      appropriate_body_period:,
                      region: region_2,
                      school: lead_school)
    FactoryBot.create(:region_award,
                      appropriate_body_period:,
                      region: region_3,
                      school: lead_school)
  end

  describe "GET /index" do
    context "when signed in as admin" do
      include_context "sign in as DfE user"

      it "returns http success" do
        get "/admin/organisations/teaching-school-hubs"
        expect(response).to have_http_status(:success)
        expect(response.body).to include(appropriate_body_period.name)
      end

      it "says when a hub has no appropriate body periods yet" do
        FactoryBot.create(:teaching_school_hub, name: "Star Teaching School Hub Network")

        get "/admin/organisations/teaching-school-hubs"
        expect(response.body).to include("No appropriate body periods yet")
      end

      it "shows each hub with its provisioning school" do
        get "/admin/organisations/teaching-school-hubs"
        expect(response.body).to include("Provisioned by #{provisioning_lead_school.name}")
      end

      it "groups hubs by concurrent appropriate bodies" do
        get "/admin/organisations/teaching-school-hubs"
        expect(response.body).to include("One appropriate body")
        expect(response.body).not_to include("More than one active appropriate body")
      end

      context "when a hub has more than one active appropriate body period" do
        let(:network) { FactoryBot.create(:teaching_school_hub, name: "Star Teaching School Hub Network") }
        let(:other_hub) { FactoryBot.create(:teaching_school_hub, name: "Bright Futures Teaching School Hub") }

        before do
          FactoryBot.create(:appropriate_body_period, :teaching_school_hub,
                            teaching_school_hub: network,
                            provisioning_school: provisioning_lead_school,
                            name: "Star Teaching School Hub Pennine Lancashire")
          FactoryBot.create(:appropriate_body_period, :teaching_school_hub,
                            teaching_school_hub: network,
                            provisioning_school: lead_school,
                            name: "Star Teaching School Hub Birmingham South")
          FactoryBot.create(:appropriate_body_period, :teaching_school_hub,
                            teaching_school_hub: other_hub,
                            provisioning_school: provisioning_lead_school,
                            name: nil)
        end

        it "groups large hubs with concurrent appropriate bodies first" do
          get "/admin/organisations/teaching-school-hubs"
          expect(response.body).to include("More than one active appropriate body")
          expect(response.body.index(network.name)).to be < response.body.index(other_hub.name)
        end

        it "names each hub in the organisation" do
          get "/admin/organisations/teaching-school-hubs"
          expect(response.body).to include("<strong>Star Teaching School Hub Pennine Lancashire:</strong>")
          expect(response.body).to include("<strong>Star Teaching School Hub Birmingham South:</strong>")
        end
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

      before do
        get "/admin/organisations/teaching-school-hubs/#{teaching_school_hub.id}"
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
        expect(response.body).to include(appropriate_body_period.name)
        expect(response.body).to include(provisioning_lead_school.name)
        expect(response.body).to include(lead_school.name)
        expect(response.body).to include("West and East")
      end

      it "links back to the hubs index" do
        expect(response.body).to include(%(class="govuk-back-link"))
        expect(response.body).to include(%(href="/admin/organisations/teaching-school-hubs"))
      end

      it "captions the hub with every region code across its appropriate bodies" do
        expect(response.body).to include("R1, R2, and R3")
      end

      it "links each appropriate body to its own page" do
        expect(response.body).to include(%(href="#{admin_appropriate_body_path(appropriate_body_period)}"))
        expect(response.body).to include("View appropriate body")
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
