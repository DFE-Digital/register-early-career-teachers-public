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

private

  def path_for_step(step)
    "/school/register-mentor/#{step}"
  end
end
