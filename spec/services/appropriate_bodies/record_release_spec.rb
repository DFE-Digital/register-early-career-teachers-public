RSpec.describe AppropriateBodies::RecordRelease do
  include ActiveJob::TestHelper

  subject(:service) do
    AppropriateBodies::RecordRelease.new(
      appropriate_body:,
      pending_induction_submission:,
      author:
    )
  end

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }

  let(:pending_induction_submission) do
    FactoryBot.create(:pending_induction_submission, :finishing,
                      appropriate_body:,
                      trn: teacher.trn)
  end

  let(:author) do
    FactoryBot.create(:appropriate_body_user,
                      dfe_sign_in_organisation_id: appropriate_body.dfe_sign_in_organisation_id)
  end

  describe '#release!' do
    context "with an ongoing induction period" do
      let!(:induction_period) do
        FactoryBot.create(:induction_period, :ongoing, appropriate_body:, teacher:)
      end

      it 'closes the induction period setting the finished_on date and number_of_terms' do
        expect(induction_period.number_of_terms).to be_blank
        expect(induction_period.finished_on).to be_blank
        expect(induction_period.outcome).to be_blank

        service.release!
        induction_period.reload

        expect(induction_period.number_of_terms).to be_present
        expect(induction_period.finished_on).to be_present
        expect(induction_period.outcome).to be_blank

        expect(induction_period.number_of_terms).to eql(pending_induction_submission.number_of_terms)
        expect(induction_period.finished_on).to eql(pending_induction_submission.finished_on)
      end

      it "records an induction closed event" do
        allow(Events::Record).to receive(:record_induction_period_closed_event!).and_call_original

        service.release!

        expect(Events::Record).to have_received(:record_induction_period_closed_event!).with(
          appropriate_body:,
          teacher:,
          induction_period:,
          author: an_instance_of(Sessions::Users::AppropriateBodyUser)
        )

        perform_enqueued_jobs

        expect(Event.last.event_type).to eq("induction_period_closed")
      end

      it 'sets the pending_induction_submission delete_at timestamp to 24h in the future' do
        freeze_time do
          service.release!
          pending_induction_submission.reload
          expect(pending_induction_submission.delete_at).to eql(24.hours.from_now)
        end
      end
    end

    context "without an ongoing induction period" do
      it 'raises an error' do
        expect { service.release! }.to raise_error(AppropriateBodies::CloseInduction::TeacherHasNoOngoingInductionPeriod)
      end
    end
  end
end
