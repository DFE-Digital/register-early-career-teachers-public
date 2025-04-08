RSpec.describe Admin::CreateInductionPeriod do
  subject(:service) { described_class.new(author:, teacher:, params:) }

  let(:induction_period) { service.induction_period }
  let(:admin) { FactoryBot.create(:user, email: 'admin-user@education.gov.uk') }
  let(:author) { Sessions::Users::DfEPersona.new(email: admin.email) }
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:teacher) { FactoryBot.create(:teacher) }

  let(:appropriate_body_id) { appropriate_body.id }
  let(:started_on) { Date.parse('2025-1-1') }
  let(:finished_on) { Date.parse('2025-3-1') }
  let(:induction_programme) { 'fip' }
  let(:number_of_terms) { 1 }

  let(:params) do
    {
      appropriate_body_id:,
      started_on:,
      finished_on:,
      induction_programme:,
      number_of_terms:
    }
  end

  describe '#create_induction_period!' do
    include ActiveJob::TestHelper

    before do
      allow(::TRS::APIClient).to receive(:new).and_return(TRS::FakeAPIClient.new)
    end

    it 'has the right attributes' do
      service.create_induction_period!

      aggregate_failures('assigning the right attributes') do
        expect(induction_period.appropriate_body).to eql(appropriate_body)
        expect(induction_period.teacher).to eql(teacher)
        expect(induction_period.started_on).to eql(started_on)
        expect(induction_period.induction_programme).to eql(induction_programme)
        expect(induction_period.number_of_terms).to eq(number_of_terms)
        expect(induction_period.finished_on).to eql(finished_on)
      end
    end

    it 'saves induction period record' do
      expect { service.create_induction_period! }.to change(InductionPeriod, :count).by(1)
    end

    context 'when creating an initial period' do
      before do
        allow(BeginECTInductionJob).to receive(:perform_later)
      end

      it 'notifies TRS of the new induction start date' do
        service.create_induction_period!

        expect(BeginECTInductionJob).to have_received(:perform_later).with(
          trn: teacher.trn,
          start_date: started_on
        )
      end
    end

    context 'with existing periods' do
      before do
        FactoryBot.create(
          :induction_period,
          teacher:,
          appropriate_body:,
          started_on: Date.parse('2024-1-1'),
          finished_on: Date.parse('2024-6-1'),
          number_of_terms: 2
        )
      end

      context 'when creating an earlier period' do
        let(:started_on) { Date.parse('2023-1-1') }

        before do
          allow(BeginECTInductionJob).to receive(:perform_later)
        end

        it 'notifies TRS of the earlier induction start date' do
          service.create_induction_period!

          expect(BeginECTInductionJob).to have_received(:perform_later).with(
            trn: teacher.trn,
            start_date: started_on
          )
        end

        context 'and new period is not finished' do
          let(:finished_on) { nil }
          let(:number_of_terms) { nil }

          it 'raises an error' do
            expect { service.create_induction_period! }.to raise_error(
              ActiveRecord::RecordInvalid,
              "Validation failed: Finished on End date is required for inserted periods"
            )
          end
        end
      end

      context 'when creating a later period' do
        before do
          allow(BeginECTInductionJob).to receive(:perform_later)
        end

        it 'does not notify TRS' do
          service.create_induction_period!

          expect(BeginECTInductionJob).not_to have_received(:perform_later).with(
            trn: teacher.trn,
            start_date: started_on
          )
        end
      end
    end

    it 'writes an event' do
      service.create_induction_period!

      perform_enqueued_jobs

      event = Event.last

      aggregate_failures do
        expect(event.event_type).to eql('induction_period_opened')
        expect(event.appropriate_body).to eql(appropriate_body)
        expect(event.teacher).to eql(teacher)
        expect(event.induction_period).to eql(service.induction_period)
      end
    end
  end
end
