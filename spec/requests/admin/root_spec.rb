RSpec.describe "Admin root", type: :request do
  describe "GET /admin" do
    it "redirects to teachers path" do
      get "/admin"
      expect(response).to redirect_to(admin_teachers_path)
    end
  end
end
