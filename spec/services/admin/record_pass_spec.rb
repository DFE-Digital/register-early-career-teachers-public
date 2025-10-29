RSpec.describe Admin::RecordPass do
  subject(:service) do
    described_class.new(
      appropriate_body:,
      pending_induction_submission:,
      author:,
      note:,
      zendesk_ticket_id: '#123456'
    )
  end

  include_context 'test trs api client'

  let(:author) { FactoryBot.create(:dfe_user, email: 'dfe_user@education.gov.uk') }
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:teacher) { FactoryBot.create(:teacher) }

  let(:pending_induction_submission) do
    FactoryBot.create(:pending_induction_submission,
                      trn: teacher.trn,
                      finished_on: 1.day.ago.to_date,
                      number_of_terms: 6)
  end

  let(:note) { 'Original outcome recorded in error' }

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
        expect(Events::Record).to receive(:record_teacher_passes_induction_event!).with(
          appropriate_body:,
          teacher:,
          induction_period:,
          author:,
          body: note,
          zendesk_ticket_id: '123456'
        )
        service.pass!
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
