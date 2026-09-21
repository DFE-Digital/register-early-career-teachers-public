RSpec.describe Admin::Teachers::UndoRegistrationWizard::StartStep do
  subject(:step) { described_class.new }

  describe "#next_step" do
    it "returns the confirm step" do
      expect(step.next_step).to eq(:confirm)
    end
  end
end
