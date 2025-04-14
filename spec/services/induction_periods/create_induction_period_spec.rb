describe 'InductionPeriods::CreateInductionPeriod' do
  include ActiveJob::TestHelper

  describe '#initialize' do
    subject { InductionPeriods::CreateInductionPeriod.new(author:, teacher:, params:) }

    let(:teacher) { FactoryBot.create(:teacher) }
    let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
    let(:started_on) { 3.weeks.ago.to_date }
    let(:induction_programme) { 'cip' }
    let(:params) do
      {
        started_on:,
        appropriate_body_id: appropriate_body.id,
        induction_programme:
      }
    end
    let(:author) do
      Sessions::Users::AppropriateBodyUser.new(
        name: 'A user',
        email: 'ab_user@something.org',
        dfe_sign_in_user_id: SecureRandom.uuid,
        dfe_sign_in_organisation_id: appropriate_body.dfe_sign_in_organisation_id
      )
    end

    it 'accepts and assigns the author, teacher and params' do
      expect(subject.author).to eql(author)
      expect(subject.teacher).to eql(teacher)
      expect(subject.params).to eql(params)
    end

    describe '#create_induction_period!' do
      context 'when the induction period is valid' do
        it 'saves the record' do
          induction_period = subject.create_induction_period!

          expect(induction_period).to be_a(InductionPeriod)
          expect(induction_period).to be_persisted
        end

        it 'records an induction_period_opened event' do
          subject.create_induction_period!

          perform_enqueued_jobs

          expect(Event.last.event_type).to eql('induction_period_opened')
        end

        it 'creates the event with the expected values' do
          freeze_time do
            subject.create_induction_period!

            perform_enqueued_jobs

            last_event = Event.last

            expect(last_event.appropriate_body).to eql(appropriate_body)
            expect(last_event.teacher).to eql(teacher)
            expect(last_event.happened_at.to_date).to eql(started_on)
          end
        end

        it 'returns the induction period and exposes it as a attr' do
          returned_value = subject.create_induction_period!

          expect(returned_value).to be_an(InductionPeriod)
          expect(subject.induction_period).to be(returned_value)
        end
      end

      context 'when the induction period is invalid' do
        before { allow(Events::Record).to receive(:record_induction_period_opened_event!).and_call_original }

        let(:started_on) { 3.weeks.from_now.to_date }

        it 'raises error and does not record event' do
          expect { subject.create_induction_period! }.to raise_error(ActiveRecord::RecordInvalid)

          perform_enqueued_jobs

          expect(Event.count).to be_zero
        end
      end
    end
  end
end
