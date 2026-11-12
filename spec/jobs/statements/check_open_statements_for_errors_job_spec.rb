RSpec.describe Statements::CheckOpenStatementsForErrorsJob do
  describe "#perform" do
    it "calls Statements::MarkAsPayable.check_open_statements_for_errors" do
      expect(Statements::MarkAsPayable).to receive(:check_open_statements_for_errors).once

      described_class.new.perform
    end
  end
end
