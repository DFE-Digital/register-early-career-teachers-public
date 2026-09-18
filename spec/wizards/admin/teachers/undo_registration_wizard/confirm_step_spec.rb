RSpec.describe Admin::Teachers::UndoRegistrationWizard::ConfirmStep do
  subject(:step) { described_class.new }

  describe "#previous_step" do
    it "returns the start step" do
      expect(step.previous_step).to eq(:start)
    end
  end

  describe "#next_step" do
    it "returns the confirmation step" do
      expect(step.next_step).to eq(:confirmation)
    end
  end
end
