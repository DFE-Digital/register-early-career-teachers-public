RSpec.describe AnalyticsBatchJob, type: :job do
  let(:appropriate_body) { FactoryBot.build(:appropriate_body) }

  let(:pending_induction_submission_batch) do
    FactoryBot.build(:pending_induction_submission_batch, appropriate_body:)
  end

  before do
    allow(DfE::Analytics::SendEvents).to receive(:do)

    FactoryBot.create_list(:induction_period, 3).each do |induction_period|
      FactoryBot.create(:event,
                        event_type: 'induction_period_opened',
                        induction_period_id: induction_period.id,
                        pending_induction_submission_batch_id: pending_induction_submission_batch.id)
    end

    FactoryBot.create(:event,
                      event_type: 'teacher_imported_from_trs',
                      pending_induction_submission_batch_id: pending_induction_submission_batch.id)

    described_class.perform_now(pending_induction_submission_batch_id: pending_induction_submission_batch.id)
  end

  describe '#perform' do
    it 'sends events' do
      expect(DfE::Analytics::SendEvents).to have_received(:do).exactly(3).times do |events|
        expect(events.first['event_type']).to eq('bulk_upload_action')
        expect(events.first['entity_table_name']).to eq('bulk_upload_actions')

        data_array = events.first['data']

        event_type = data_array.find { |entry| entry['key'] == 'event_type' }
        expect(event_type['value']).to eq(%w[induction_period_opened])
        expect(event_type['value']).not_to eq(%w[teacher_imported_from_trs])
      end
    end
  end
end
