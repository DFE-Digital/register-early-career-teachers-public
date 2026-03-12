RSpec.describe Statements::MarkAsPayableJob do
  describe "#perform" do
    it "calls Statements::MarkAsPayable.mark_all_eligible!" do
      expect(Statements::MarkAsPayable).to receive(:mark_all_eligible!)

      described_class.new.perform
    end
  end
end
