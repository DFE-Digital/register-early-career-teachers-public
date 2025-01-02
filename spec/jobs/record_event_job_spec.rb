RSpec.describe(RecordEventJob) do
  describe '#perform' do
    it 'creates an Event record' do
      event_attributes = FactoryBot.attributes_for(:event)

      allow(Event).to receive(:create!).and_call_original

      expect { RecordEventJob.perform_now(**event_attributes) }.to change { Event.count }.by(1)

      expect(Event).to have_received(:create!).once.with(event_attributes)
    end
  end
end
