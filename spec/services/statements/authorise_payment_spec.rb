RSpec.describe Statements::AuthorisePayment do
  subject { described_class.new(statement) }

  let(:statement) { create(:statement, :payable, marked_as_paid_at: nil) }

  describe "#authorise" do
    context "can authorise payment" do
      before { allow(statement).to receive(:can_authorise_payment?).and_return(true) }

      it "sets marked_as_paid_at and status to paid" do
        expect(subject.authorise).to be(true)
        statement.reload
        expect(statement.marked_as_paid_at).to be_present
        expect(statement.status).to eq("paid")
      end
    end

    context "cannot authorise payment" do
      before { allow(statement).to receive(:can_authorise_payment?).and_return(false) }

      it "return false" do
        expect(subject.authorise).to be(false)
      end
    end
  end
end
