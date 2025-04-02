RSpec.describe Admin::RevertClaim do
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
    allow(Events::Record).to receive_messages(
      record_admin_reverts_teacher_claim_event!: true,
      record_admin_deletes_induction_period!: true
    )
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

      it "records an event with the correct parameters" do
        expect(Events::Record).to receive(:record_admin_reverts_teacher_claim_event!).with(
          author:,
          appropriate_body:,
          teacher:
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

      it "does not record a revert event" do
        expect(Events::Record).not_to receive(:record_admin_reverts_teacher_claim_event!)
        service.revert_claim
      end
    end
  end
end
