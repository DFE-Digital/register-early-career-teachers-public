RSpec.describe Statements::MarkAsPayableJob do
  describe "#perform" do
    it "calls Statements::MarkAsPayable.mark_all!" do
      expect(Statements::MarkAsPayable).to receive(:mark_all!)

      described_class.new.perform
    end
  end
end
