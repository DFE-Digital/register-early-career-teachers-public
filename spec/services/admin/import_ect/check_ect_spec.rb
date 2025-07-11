RSpec.describe Admin::ImportECT::CheckECT do
  subject { Admin::ImportECT::CheckECT.new(pending_induction_submission:) }

  let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission, appropriate_body: nil) }

  describe "#initialize" do
    it "assigns the provided pending induction submission params" do
      expect(subject.pending_induction_submission).to eql(pending_induction_submission)
    end
  end

  describe "#import" do
    it "sets the confirmed attribute to true" do
      subject.import
      expect(subject.pending_induction_submission.confirmed).to be(true)
    end

    it "sets confirmed_at timestamp to now" do
      subject.import
      expect(subject.pending_induction_submission.confirmed_at).to be_within(1.second).of(Time.zone.now)
    end

    it "results in the pending_induction_submission being valid" do
      subject.import
      expect(subject.pending_induction_submission).to be_valid(:check_ect)
    end

    it "returns true when successful" do
      result = subject.import
      expect(result).to be(true)
    end

    context "when the database save fails" do
      let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission, appropriate_body: nil) }

      before do
        allow(pending_induction_submission).to receive(:save).and_return(false)
      end

      it "returns false" do
        result = subject.import
        expect(result).to be(false)
      end

      it "sets confirmed to true (even though save fails)" do
        subject.import
        expect(subject.pending_induction_submission.confirmed).to be(true)
      end

      it "sets confirmed_at timestamp (even though save fails)" do
        subject.import
        expect(subject.pending_induction_submission.confirmed_at).to be_within(1.second).of(Time.zone.now)
      end
    end
  end
end
