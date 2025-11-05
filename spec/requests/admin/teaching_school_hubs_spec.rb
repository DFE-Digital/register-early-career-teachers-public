RSpec.describe "Admin::TeachingSchoolHubs", type: :request do
  let!(:teaching_school_hub) do
    FactoryBot.create(:teaching_school_hub)
  end

  describe "GET /index" do
    context "with an authenticated DfE user" do
      include_context "sign in as DfE user"
      it "returns http success" do
        get "/admin/organisations/teaching-school-hubs"
        expect(response).to have_http_status(:success)
        expect(response.body).to include(teaching_school_hub.name)
      end
    end
  end

  describe "GET /show" do
    context "with an authenticated DfE user" do
      include_context "sign in as DfE user"
      it "returns http success" do
        get "/admin/organisations/teaching-school-hubs/#{teaching_school_hub.id}"
        expect(response).to have_http_status(:success)
        expect(response.body).to include(teaching_school_hub.name)
      end
    end
  end
end
