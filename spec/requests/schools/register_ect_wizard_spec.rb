describe "Schools::RegisterECTWizardController", :enable_schools_interface do
  let(:school) { FactoryBot.create(:school) }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school:) }
  let(:ect_at_school_period_id) { ect_at_school_period.id }

  describe "GET #new" do
    subject { get path_for_step("what-you-will-need") }

    it_behaves_like "an induction redirectable route"
  end

  describe "POST #create" do
    subject { post(path_for_step("confirmation"), params:) }

    let(:params) { { edit: { ect_at_school_period_id: } } }

    it_behaves_like "an induction redirectable route"
  end

  describe "section 41 approval lost" do
    let(:gias_school) { FactoryBot.create(:gias_school, :independent_school_type, :not_section_41) }
    let(:school) { FactoryBot.create(:school, urn: gias_school.urn, gias_school:) }
    let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school:) }
    let!(:training_period) { FactoryBot.create(:training_period, :ongoing, ect_at_school_period:) }

    before { sign_in_as(:school_user, method: :dfe_sign_in, school:) }

    it "prevents access to the wizard and redirects to the ECT list" do
      get path_for_step("what-you-will-need")

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(schools_ects_home_path)
    end
  end

  describe "section 41 approval lost without ongoing training periods" do
    let(:gias_school) { FactoryBot.create(:gias_school, :independent_school_type, :not_section_41) }
    let(:school) { FactoryBot.create(:school, urn: gias_school.urn, gias_school:) }

    before { sign_in_as(:school_user, method: :dfe_sign_in, school:) }

    it "redirects to the school access denied page" do
      get path_for_step("what-you-will-need")

      expect(response).to redirect_to(schools_access_denied_path)
    end
  end

private

  def path_for_step(step)
    "/school/register-ect/#{step}"
  end
end
