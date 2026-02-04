RSpec.describe Admin::RevertClaim do
  subject(:service) do
    described_class.new(
      appropriate_body_period:,
      teacher:,
      author:,
      induction_period:
    )
  end

  include_context "test TRS API returns a teacher"
  include ActiveJob::TestHelper

  before do
    allow(Events::Record).to receive_messages(
      record_teacher_induction_status_reset_event!: true,
      record_induction_period_deleted_event!: true
    )
  end

  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period) }
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:author) { FactoryBot.create(:user) }
  let!(:induction_period) { FactoryBot.create(:induction_period, teacher:, appropriate_body_period:) }

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
        expect(Events::Record).to receive(:record_teacher_induction_status_reset_event!).with(
          author:,
          appropriate_body_period:,
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
        expect(Events::Record).not_to receive(:record_teacher_induction_status_reset_event!)
        service.revert_claim
      end
    end
  end
end
