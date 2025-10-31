RSpec.describe AppropriateBodies::RecordPass do
  include ActiveJob::TestHelper

  subject(:service) do
    described_class.new(
      appropriate_body:,
      pending_induction_submission:,
      author:
    )
  end

  include_context 'test trs api client'

  let(:author) do
    FactoryBot.create(:appropriate_body_user,
                      dfe_sign_in_organisation_id: appropriate_body.dfe_sign_in_organisation_id)
  end

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:teacher) { FactoryBot.create(:teacher) }

  let(:pending_induction_submission) do
    FactoryBot.create(:pending_induction_submission,
                      trn: teacher.trn,
                      finished_on: 1.day.ago.to_date,
                      number_of_terms: 6)
  end

  describe "#pass!" do
    context "with an ongoing induction period" do
      let!(:induction_period) do
        FactoryBot.create(:induction_period, :ongoing,
                          appropriate_body:,
                          teacher:,
                          started_on: '2024-1-1')
      end

      it "updates the induction period with pass outcome" do
        service.pass!

        expect(induction_period.reload).to have_attributes(
          finished_on: pending_induction_submission.finished_on,
          outcome: "pass",
          number_of_terms: pending_induction_submission.number_of_terms
        )
      end

      it 'sets the pending_induction_submission delete_at timestamp to 24h in the future' do
        freeze_time do
          service.pass!
          pending_induction_submission.reload
          expect(pending_induction_submission.delete_at).to eql(24.hours.from_now)
        end
      end

      it "enqueues a PassECTInductionJob" do
        expect {
          service.pass!
        }.to have_enqueued_job(PassECTInductionJob).with(
          trn: pending_induction_submission.trn,
          start_date: induction_period.started_on,
          completed_date: pending_induction_submission.finished_on
        )
      end

      it "records an induction passed event" do
        allow(Events::Record).to receive(:record_teacher_passes_induction_event!).and_call_original

        service.pass!

        expect(Events::Record).to have_received(:record_teacher_passes_induction_event!).with(
          appropriate_body:,
          teacher:,
          induction_period:,
          author: an_instance_of(Sessions::Users::AppropriateBodyUser)
        )

        perform_enqueued_jobs

        expect(Event.last.event_type).to eq("teacher_passes_induction")
      end

      context "when induction submission is invalid" do
        let(:pending_induction_submission) do
          FactoryBot.create(:pending_induction_submission,
                            trn: teacher.trn,
                            finished_on: '2020-1-1',
                            number_of_terms: 6)
        end

        it "does not update the induction period" do
          expect { service.pass! }.to raise_error(ActiveRecord::RecordInvalid)
          expect(induction_period.outcome).to be_nil
        end

        it "does not enqueue a PassECTInductionJob" do
          expect {
            expect { service.pass! }.to raise_error(ActiveRecord::RecordInvalid)
          }.not_to have_enqueued_job(PassECTInductionJob)
        end

        it "does not enqueue a RecordEventJob" do
          expect {
            expect { service.pass! }.to raise_error(ActiveRecord::RecordInvalid)
          }.not_to have_enqueued_job(RecordEventJob)
        end
      end
    end

    context "without an ongoing induction period" do
      it do
        expect { subject.pass! }.to raise_error(AppropriateBodies::CloseInduction::TeacherHasNoOngoingInductionPeriod)
      end
    end

    context "when ongoing induction period only has the legacy programme type" do
      let!(:induction_period) do
        FactoryBot.create(:induction_period, :ongoing, :legacy_programme_type,
                          appropriate_body:,
                          teacher:,
                          started_on: '2024-1-1')
      end

      it "populates the new programme type and outcome" do
        service.pass!

        expect(induction_period.reload).to have_attributes(
          training_programme: 'provider_led',
          outcome: 'pass'
        )
      end
    end
  end
end
