RSpec.shared_examples "a route blocked when the registration window is closed" do
  around do |example|
    travel_to(date)
    example.run
  end

  before do
    sign_in_as(:school_user, school:)
    subject
  end

  context "when the registration window is closed" do
    let(:date) { Schools::RegistrationWindow::CLOSED_PERIOD.begin }

    it "redirects to the registration window closed page" do
      expect(response).to redirect_to(schools_registration_window_closed_path)
    end
  end

  context "when the registration window is open" do
    let(:date) { Schools::RegistrationWindow.reopens_on }

    it "does not redirect to the registration window closed page" do
      expect(response).not_to redirect_to(schools_registration_window_closed_path)
    end
  end
end
