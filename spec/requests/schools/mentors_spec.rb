RSpec.describe "Mentor summary", :enable_schools_interface do
  let(:mentor) { FactoryBot.create(:mentor_at_school_period, school:) }
  let(:school) { FactoryBot.create(:school) }

  describe "GET #index" do
    subject { get schools_mentors_path }

    it_behaves_like "an induction redirectable route"
  end

  describe "GET #show" do
    subject { get("/school/mentors/#{mentor.id}") }

    it_behaves_like "an induction redirectable route"
  end
end
