RSpec.describe "Schools registration window banner" do
  let(:school) { FactoryBot.create(:school) }

  context "when the registration window is closed" do
    before do
      allow(Schools::RegistrationWindow).to receive(:closed?).and_return(true)
    end

    it "displays for school users" do
      sign_in_as(:school_user, school:)
      get "/school/home/ects"
      expect(response.body).to include("Registration not currently open")
    end

    it "does not display for non-school users" do
      appropriate_body_period = FactoryBot.create(:appropriate_body_period)
      sign_in_as(:appropriate_body_user, appropriate_body: appropriate_body_period)
      get "/appropriate-body"
      expect(response.body).not_to include("Registration not currently open")
    end
  end

  context "when the registration window is open" do
    before do
      allow(Schools::RegistrationWindow).to receive(:closed?).and_return(false)
    end

    it "does not display on schools pages" do
      sign_in_as(:school_user, school:)
      get "/school/home/ects"
      expect(response.body).not_to include("Registration not currently open")
    end
  end
end
