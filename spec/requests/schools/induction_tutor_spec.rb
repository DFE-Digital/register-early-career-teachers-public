RSpec.describe "Induction Tutor", :enable_schools_interface do
  let(:school) { FactoryBot.create(:school, :with_induction_tutor) }

  describe "GET #show" do
    context "when not signed in" do
      it "redirects to the root page" do
        get schools_induction_tutor_path

        expect(response).to redirect_to(root_path)
      end
    end

    context "when signed in as a non-school user" do
      include_context "sign in as DfE user"

      it "returns unauthorized" do
        get schools_induction_tutor_path

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in as a school user" do
      before do
        sign_in_as(:school_user, school:)
        get schools_induction_tutor_path
      end

      it "returns ok" do
        expect(response).to have_http_status(:ok)
      end

      it "shows the induction tutor name and email address" do
        expect(response.body).to include(school.induction_tutor_name)
        expect(response.body).to include(school.induction_tutor_email)
      end
    end
  end
end
