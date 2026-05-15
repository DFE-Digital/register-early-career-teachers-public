RSpec.describe "Schools::RegistrationWindowClosedController" do
  let(:school) { FactoryBot.create(:school) }

  describe "GET #show" do
    subject(:show) { get schools_registration_window_closed_path }

    context "when not signed in" do
      it "redirects to the root page" do
        show
        expect(response).to redirect_to(root_path)
      end
    end

    context "when signed in as a school user" do
      before do
        sign_in_as(:school_user, school:)
        show
      end

      it "returns a successful response" do
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
