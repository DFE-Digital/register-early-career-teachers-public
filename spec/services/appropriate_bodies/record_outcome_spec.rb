require "rails_helper"

RSpec.describe AppropriateBodies::RecordOutcome do
  include ActiveJob::TestHelper
  include_context 'fake trs api client'

  subject(:service) do
    described_class.new(
      appropriate_body:,
      pending_induction_submission:,
      teacher:,
      author:
    )
  end

  let(:author) do
    Sessions::Users::AppropriateBodyUser.new(
      name: 'A user',
      email: 'ab_user@something.org',
      dfe_sign_in_user_id: SecureRandom.uuid,
      dfe_sign_in_organisation_id: appropriate_body.dfe_sign_in_organisation_id
    )
  end

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:induction_period) { FactoryBot.create(:induction_period, teacher:) }
  let(:pending_induction_submission) do
    FactoryBot.create(:pending_induction_submission,
                      trn: teacher.trn,
                      finished_on: 1.day.ago.to_date,
                      number_of_terms: 6)
  end

  before do
    allow(Teachers::InductionPeriod).to receive(:new)
      .with(teacher)
      .and_return(double(active_induction_period: induction_period))
  end

  describe "#pass!" do
    context "when happy path" do
      it "updates the induction period with pass outcome" do
        service.pass!

        expect(induction_period.reload).to have_attributes(
          finished_on: pending_induction_submission.finished_on,
          outcome: "pass",
          number_of_terms: pending_induction_submission.number_of_terms
        )
      end

      it "enqueues a PassECTInductionJob" do
        expect {
          service.pass!
        }.to have_enqueued_job(PassECTInductionJob).with(
          trn: pending_induction_submission.trn,
          completion_date: pending_induction_submission.finished_on.to_s,
          pending_induction_submission_id: pending_induction_submission.id
        )
      end

      it "records a pass event" do
        allow(Events::Record).to receive(:record_appropriate_body_passes_teacher_event).and_call_original

        service.pass!

        expect(Events::Record).to have_received(:record_appropriate_body_passes_teacher_event).with(
          appropriate_body:,
          teacher:,
          induction_period:,
          author: an_instance_of(Sessions::Users::AppropriateBodyUser)
        )

        perform_enqueued_jobs

        expect(Event.last.event_type).to eq("appropriate_body_passes_teacher")
      end
    end

    context "when induction period update fails" do
      before do
        allow(induction_period).to receive(:update)
          .and_raise(ActiveRecord::RecordNotFound)
      end

      it "bubbles up the error" do
        expect { service.pass! }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "#fail!" do
    context "when successful" do
      it "updates the induction period with fail outcome" do
        service.fail!

        expect(induction_period.reload).to have_attributes(
          finished_on: pending_induction_submission.finished_on,
          outcome: "fail",
          number_of_terms: pending_induction_submission.number_of_terms
        )
      end

      it "enqueues a FailECTInductionJob" do
        expect {
          service.fail!
        }.to have_enqueued_job(FailECTInductionJob).with(
          trn: pending_induction_submission.trn,
          completion_date: pending_induction_submission.finished_on.to_s,
          pending_induction_submission_id: pending_induction_submission.id
        )
      end

      it "records a fail event" do
        allow(Events::Record).to receive(:record_appropriate_body_fails_teacher_event).and_call_original

        service.fail!

        expect(Events::Record).to have_received(:record_appropriate_body_fails_teacher_event).with(
          appropriate_body:,
          teacher:,
          induction_period:,
          author: an_instance_of(Sessions::Users::AppropriateBodyUser)
        )

        perform_enqueued_jobs

        expect(Event.last.event_type).to eq("appropriate_body_fails_teacher")
      end
    end

    context "when induction period update fails" do
      before do
        allow(induction_period).to receive(:update)
          .and_raise(ActiveRecord::RecordNotFound)
      end

      it "bubbles up the error" do
        expect { service.fail! }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
