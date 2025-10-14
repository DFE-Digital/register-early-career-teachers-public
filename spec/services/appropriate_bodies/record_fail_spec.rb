RSpec.describe AppropriateBodies::RecordFail do
  include ActiveJob::TestHelper

  subject(:service) do
    AppropriateBodies::RecordFail.new(
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
        allow(Events::Record).to receive(:record_teacher_fails_induction_event!).and_call_original

        service.fail!

        expect(Events::Record).to have_received(:record_teacher_fails_induction_event!).with(
          appropriate_body:,
          teacher:,
          induction_period:,
          author: an_instance_of(Sessions::Users::AppropriateBodyUser)
        )

        perform_enqueued_jobs

        expect(Event.last.event_type).to eq("teacher_fails_induction")
      end

      context "when the author is a DfE user" do
        let(:dfe_user) { FactoryBot.create(:user, email: 'dfe_user@education.gov.uk') }
        let(:author) do
          Sessions::Users::DfEUser.new(
            email: dfe_user.email
          )
        end

        before do
          allow(author).to receive(:dfe_user?).and_return(true)
        end

        it "records an admin fail event" do
          allow(Events::Record).to receive(:record_teacher_fails_induction_event!).and_call_original

          service.fail!

          expect(Events::Record).to have_received(:record_teacher_fails_induction_event!).with(
            appropriate_body:,
            teacher:,
            induction_period:,
            author:
          )

          perform_enqueued_jobs

          expect(Event.last.event_type).to eq("teacher_fails_induction")
        end
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
