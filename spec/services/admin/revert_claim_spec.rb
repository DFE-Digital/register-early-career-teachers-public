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

  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period) }
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:user) { FactoryBot.create(:user, :admin) }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }
  let!(:induction_period) { FactoryBot.create(:induction_period, teacher:, appropriate_body_period:, started_on: 1.year.ago) }

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
        service.revert_claim

        expect(Event.where(event_type: "teacher_induction_status_reset").sole).to have_attributes(
          appropriate_body_period_id: appropriate_body_period.id,
          teacher_id: teacher.id
        )
      end
    end

    context "when the teacher has other induction periods" do
      let!(:other_induction_period) { FactoryBot.create(:induction_period, teacher:, started_on: 2.years.ago, finished_on: 13.months.ago) }

      it "does not enqueue a ResetInductionJob" do
        expect {
          service.revert_claim
        }.not_to have_enqueued_job(ResetInductionJob)
      end

      it "does not record a revert event" do
        service.revert_claim

        expect(Event.where(event_type: "teacher_induction_status_reset")).to be_empty
      end
    end
  end
end
