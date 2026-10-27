describe "Schools access guard" do
  let(:school) { gias_school.school }

  describe "GET /school/home/ects" do
    subject(:perform_request) { get schools_ects_home_path }

    context "when the gias school is closed" do
      let(:gias_school) { FactoryBot.create(:gias_school, :with_school, :state_school_type, status: :closed) }

      before { sign_in_as(:school_user, method: :dfe_sign_in, school:) }

      it "redirects to the school access denied page" do
        perform_request

        expect(response).to redirect_to(schools_access_denied_path)
      end
    end

    context "when the gias school is proposed to open" do
      let(:gias_school) { FactoryBot.create(:gias_school, :with_school, :state_school_type, status: :proposed_to_open) }

      before { sign_in_as(:school_user, method: :dfe_sign_in, school:) }

      it "redirects to the school access denied page" do
        perform_request

        expect(response).to redirect_to(schools_access_denied_path)
      end
    end

    context "when the gias school is proposed to close" do
      let(:gias_school) { FactoryBot.create(:gias_school, :with_school, :state_school_type, status: :proposed_to_close) }

      before { sign_in_as(:school_user, method: :dfe_sign_in, school:) }

      it "allows access to the ects home page" do
        perform_request

        expect(response).to have_http_status(:ok)
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
      let(:gias_school) { FactoryBot.create(:gias_school, :with_school, :independent_school_type, :not_section_41, status: :open) }

      before { sign_in_as(:school_user, method: :dfe_sign_in, school:) }

      it "redirects to the school access denied page" do
        perform_request

        expect(response).to redirect_to(schools_access_denied_path)
      end
    end

    context "when the school is independent, not section 41 approved, and has ongoing training" do
      let(:gias_school) { FactoryBot.create(:gias_school, :with_school, :independent_school_type, :not_section_41, status: :open) }

      before do
        ect_at_school_period = FactoryBot.create(:ect_at_school_period, :unfinished, school:)
        FactoryBot.create(:training_period, :unfinished, ect_at_school_period:)
        sign_in_as(:school_user, method: :dfe_sign_in, school:)
      end

      it "allows access to the ects home page" do
        perform_request

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /school/access-denied" do
    subject(:perform_request) { get schools_access_denied_path }

    before { sign_in_as(:school_user, method: :dfe_sign_in, school:) }

    context "when the school is independent, not section 41 approved, and has no ongoing training" do
      let(:gias_school) { FactoryBot.create(:gias_school, :with_school, :independent_school_type, :not_section_41, status: :open) }

      it "shows the independent school access denied page" do
        perform_request

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("You cannot use Register early career teachers for #{school.name}")
      end
    end

    context "when the gias school is closed" do
      let(:gias_school) { FactoryBot.create(:gias_school, :with_school, :state_school_type, status: :closed) }

      it "shows the general access denied page" do
        perform_request

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("You cannot access the Register early career teachers service for #{school.name}")
      end
    end
  end
end
