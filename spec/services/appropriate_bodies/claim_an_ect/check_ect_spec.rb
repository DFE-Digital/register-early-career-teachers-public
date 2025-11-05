RSpec.describe AppropriateBodies::ClaimAnECT::CheckECT do
  subject { AppropriateBodies::ClaimAnECT::CheckECT.new(appropriate_body_period:, pending_induction_submission:) }

  let(:appropriate_body_period) { FactoryBot.build(:appropriate_body) }
  let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission) }

  describe "#initialize" do
    it "assigns the provided appropriate body and pending induction submission params" do
      expect(subject.appropriate_body_period).to eql(appropriate_body_period)
      expect(subject.pending_induction_submission).to eql(pending_induction_submission)
    end
  end

  describe "#begin_claim" do
    context "when confirmed = true (box is checked)" do
      it "sets the confirmed attribute to true" do
        subject.begin_claim!
        expect(subject.pending_induction_submission.confirmed).to be(true)
      end

      it "sets confirmed_at timestamp to now" do
        subject.begin_claim!
        expect(subject.pending_induction_submission.confirmed_at).to be_within(1.second).of(Time.zone.now)
      end

      it "results in the pending_induction_submission being valid" do
        subject.begin_claim!
        expect(subject.pending_induction_submission).to be_valid(:check_ect)
      end
    end
  end
end
