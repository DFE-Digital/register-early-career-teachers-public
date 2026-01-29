describe "Schools access guard", :enable_schools_interface do
  describe "GET /school/home/ects" do
    subject(:perform_request) { get schools_ects_home_path }

    context "when the gias school is closed" do
      let(:gias_school) { FactoryBot.create(:gias_school, :with_school, :state_school_type) }
      let(:school) { gias_school.school }

      before do
        gias_school.update!(status: :closed)
        sign_in_as(:school_user, method: :dfe_sign_in, school:)
      end

      it "redirects to the school access denied page" do
        perform_request

        expect(response).to redirect_to(schools_access_denied_path)
      end
    end

    context "when the school has not been linked yet" do
      let(:gias_school) { FactoryBot.create(:gias_school, :open, :state_school_type) }

      before { sign_in_as(:school_user, method: :dfe_sign_in, school_urn: gias_school.urn) }

      it "redirects to the school access denied page and shows the gias school name" do
        perform_request

        expect(response).to redirect_to(schools_access_denied_path)
        follow_redirect!

        expect(response.body).to include(gias_school.name)
      end
    end

    context "when the school is independent, not section 41 approved, and has no ongoing training" do
      let(:gias_school) { FactoryBot.create(:gias_school, :with_school, :independent_school_type, :not_section_41) }
      let(:school) { gias_school.school }

      before { sign_in_as(:school_user, method: :dfe_sign_in, school:) }

      it "redirects to the school access denied page" do
        perform_request

        expect(response).to redirect_to(schools_access_denied_path)
      end
    end

    context "when the school is independent, not section 41 approved, and has ongoing training" do
      let(:gias_school) { FactoryBot.create(:gias_school, :with_school, :independent_school_type, :not_section_41) }
      let(:school) { gias_school.school }

      before do
        ect_at_school_period = FactoryBot.create(:ect_at_school_period, school:)
        FactoryBot.create(:training_period, :ongoing, ect_at_school_period:)
        sign_in_as(:school_user, method: :dfe_sign_in, school:)
      end

      it "allows access to the ects home page" do
        perform_request

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
