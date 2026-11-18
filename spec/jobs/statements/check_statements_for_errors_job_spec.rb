RSpec.describe Statements::CheckStatementsForErrorsJob do
  describe "#perform" do
    it "checks open and payable statements for errors" do
      expect(Statements::MarkAsPayable).to receive(:check_open_statements_for_errors).once
      expect(Statements::AuthorisePayment).to receive(:check_payable_statements_for_errors).once

      described_class.new.perform
    end
  end
end
