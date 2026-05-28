RSpec.describe "Schools registration window banner" do
  let(:school) { FactoryBot.create(:school) }

  context "between 1-14 June 2026" do
    before do
      travel_to Date.new(2026, 6, 7)
      sign_in_as(:school_user, school:)
    end

    it "displays on schools pages" do
      get "/school/home/ects"
      expect(response.body).to include("Registration not currently open")
    end

    it "does not display on non-schools pages" do
      get "/support"
      expect(response.body).not_to include("Registration not currently open")
    end
  end

  context "before 1 June 2026" do
    before do
      travel_to Date.new(2026, 5, 31)
      sign_in_as(:school_user, school:)
    end

    it "does not display on schools pages" do
      get "/school/home/ects"
      expect(response.body).not_to include("Registration not currently open")
    end
  end

  context "from 15 June 2026" do
    before do
      travel_to Date.new(2026, 6, 15)
      sign_in_as(:school_user, school:)
    end

    it "does not display on schools pages" do
      get "/school/home/ects"
      expect(response.body).not_to include("Registration not currently open")
    end
  end
end
