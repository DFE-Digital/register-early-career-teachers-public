RSpec.describe "Pages", type: :request do
  describe "GET /" do
    before { get "/" }

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end
  end

  # rubocop:disable RSpec/AnyInstance
  describe "GET /access-denied" do
    context "when a login attempt has failed" do
      before do
        allow_any_instance_of(PagesController).to receive(:session).and_return({
          invalid_user_organisation_name: "Invalid Organisation"
        })

        get "/access-denied"
      end

      it "shows the access denied page and the invalid org name" do
        expect(response).to be_successful
        expect(response.body).to include("Invalid Organisation")
      end
    end
  end
  # rubocop:enable RSpec/AnyInstance

  describe "GET /accessibility" do
    it "shows the accessibility statement" do
      get "/accessibility"
      expect(response).to be_successful
      expect(response.body).to include("Accessibility statement")
    end
  end

  describe "GET /privacy" do
    it "shows the privacy policy" do
      get "/privacy"
      expect(response).to be_successful
      expect(response.body).to include("Privacy policy")
    end
  end

  describe "GET /cookies" do
    it "shows the cookies page" do
      get "/cookies"
      expect(response).to be_successful
      expect(response.body).to include("Cookies")
    end
  end

  describe "GET /school-requirements" do
    it "shows the school requirements page" do
      get "/school-requirements"
      expect(response).to be_successful
      expect(response.body).to include("What your school needs in place to register ECTs and mentors for ECTE")
    end
  end
end
