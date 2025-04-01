RSpec.describe "Viewing the appropriate bodies index", type: :request do
  let!(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  describe "GET /admin/appropriate-bodies/:id" do
    it "redirects to sign in path" do
      get "/admin/organisations/appropriate-bodies/#{appropriate_body.id}"
      expect(response).to redirect_to(sign_in_path)
    end

    context "with an authenticated non-DfE user" do
      include_context 'sign in as non-DfE user'

      it "requires authorisation" do
        get "/admin/organisations/appropriate-bodies/#{appropriate_body.id}"

        expect(response.status).to eq(401)
      end
    end

    context "with an authenticated DfE user" do
      include_context 'sign in as DfE user'

      it "display appropriate bodies" do
        get "/admin/organisations/appropriate-bodies/#{appropriate_body.id}"

        expect(response.status).to eq(200)
        expect(response.body).to include(appropriate_body.name)
      end
    end
  end
end
