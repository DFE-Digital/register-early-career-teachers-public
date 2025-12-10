describe "Schools::Mentors::ChangeNameWizardController", :enable_schools_interface do
  let(:school) { FactoryBot.create(:school) }
  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, school:) }
  let(:mentor_at_school_period_id) { mentor_at_school_period.id }

  describe "GET #new" do
    subject { get path_for_step("edit") }

    it_behaves_like "an induction redirectable route"
  end

  describe "POST #create" do
    subject { post(path_for_step("edit"), params:) }

    let(:params) { { edit: { mentor_at_school_period_id: } } }

    it_behaves_like "an induction redirectable route"
  end

private

  def path_for_step(step)
    "/school/mentors/#{mentor_at_school_period.id}/change-name/#{step}"
  end
end
