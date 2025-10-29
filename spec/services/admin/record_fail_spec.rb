RSpec.describe Admin::RecordFail do
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

  describe "#fail!" do
    context "with an ongoing induction period" do
      let!(:induction_period) do
        FactoryBot.create(:induction_period, :ongoing,
                          appropriate_body:,
                          teacher:,
                          started_on: '2024-1-1')
      end

      it "updates the induction period with fail outcome" do
        service.fail!

        expect(induction_period.reload).to have_attributes(
          finished_on: pending_induction_submission.finished_on,
          outcome: "fail",
          number_of_terms: pending_induction_submission.number_of_terms
        )
      end

      it 'sets the pending_induction_submission delete_at timestamp to 24h in the future' do
        freeze_time do
          service.fail!
          pending_induction_submission.reload
          expect(pending_induction_submission.delete_at).to eql(24.hours.from_now)
        end
      end

      it "enqueues a FailECTInductionJob" do
        expect {
          service.fail!
        }.to have_enqueued_job(FailECTInductionJob).with(
          trn: pending_induction_submission.trn,
          start_date: induction_period.started_on,
          completed_date: pending_induction_submission.finished_on
        )
      end

      it "records an induction failed event" do
        expect(Events::Record).to receive(:record_teacher_fails_induction_event!).with(
          appropriate_body:,
          teacher:,
          induction_period:,
          author:,
          body: note,
          zendesk_ticket_id: '123456'
        )
        service.fail!
      end
    end

    context "without an ongoing induction period" do
      it do
        expect { subject.fail! }.to raise_error(AppropriateBodies::CloseInduction::TeacherHasNoOngoingInductionPeriod)
      end
    end

    context "when ongoing induction period only has a mappable legacy programme type" do
      let!(:induction_period) do
        FactoryBot.create(:induction_period, :ongoing, :legacy_programme_type,
                          appropriate_body:,
                          teacher:,
                          started_on: '2024-1-1')
      end

      it "maps the new programme type" do
        service.fail!

        expect(induction_period.reload).to have_attributes(
          induction_programme: 'fip',
          training_programme: 'provider_led',
          outcome: 'fail'
        )
      end
    end

    context "when ongoing induction period only has an unmappable legacy programme type" do
      let!(:induction_period) do
        FactoryBot.create(:induction_period, :ongoing, :pre_2021, :legacy_programme_type,
                          appropriate_body:,
                          teacher:,
                          started_on: '2024-1-1')
      end

      it "leaves the new programme type blank" do
        service.fail!

        expect(induction_period.reload).to have_attributes(
          induction_programme: 'pre_september_2021',
          training_programme: nil,
          outcome: 'fail'
        )
      end
    end
  end
end
