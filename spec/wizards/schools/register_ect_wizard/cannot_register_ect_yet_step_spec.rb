RSpec.describe Schools::RegisterECTWizard::CannotRegisterECTYetStep, type: :model do
  describe "inheritance" do
    it "inherits from Step" do
      expect(subject).to be_a(Schools::RegisterECTWizard::Step)
    end
  end
end
