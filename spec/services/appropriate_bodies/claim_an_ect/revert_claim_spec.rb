require 'rails_helper'

RSpec.describe AppropriateBodies::ClaimAnECT::RevertClaim do
  subject(:service) do
    described_class.new(
      appropriate_body:,
      teacher:,
      author:,
      induction_period:
    )
  end

  include_context 'fake trs api client'
  include ActiveJob::TestHelper

  before do
    allow(Events::Record).to receive(:record_support_revert_teacher_claim_event!).and_return(true)
  end

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:author) { FactoryBot.create(:user) }
  let!(:induction_period) { FactoryBot.create(:induction_period, teacher:, appropriate_body:) }

  describe "#revert_claim" do
    it "destroys the induction period" do
      expect { service.revert_claim }.to change(InductionPeriod, :count).by(-1)
    end

    context "when this is the teacher's only induction period" do
      it "enqueues a ResetInductionJob" do
        expect {
          service.revert_claim
        }.to have_enqueued_job(ResetInductionJob).with(trn: teacher.trn)
      end

      it "records an event with a body indicating the induction status was reset" do
        expect(Events::Record).to receive(:record_support_revert_teacher_claim_event!).with(
          author:,
          appropriate_body:,
          teacher:,
          body: "Induction status was also reset on TRS."
        )
        service.revert_claim
      end
    end

    context "when the teacher has other induction periods" do
      let!(:other_induction_period) { FactoryBot.create(:induction_period, teacher:, started_on: 2.years.ago) }

      it "does not enqueue a ResetInductionJob" do
        expect {
          service.revert_claim
        }.not_to have_enqueued_job(ResetInductionJob)
      end

      it "records an event with no body" do
        expect(Events::Record).to receive(:record_support_revert_teacher_claim_event!).with(
          author:,
          appropriate_body:,
          teacher:,
          body: nil
        )
        service.revert_claim
      end
    end
  end
end
