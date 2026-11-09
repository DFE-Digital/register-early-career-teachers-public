RSpec.describe Statements::CheckForthcomingStatementsJob do
  describe "#perform" do
    it "calls Statements::MarkAsPayable.check_forthcoming_statements!" do
      expect(Statements::MarkAsPayable).to receive(:check_forthcoming_statements!)

      described_class.new.perform
    end
  end
end
