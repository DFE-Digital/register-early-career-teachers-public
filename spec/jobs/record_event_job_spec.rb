RSpec.describe(RecordEventJob) do
  describe '#perform' do
    Event::EVENT_TYPES.each do |event_type|
      it "creates an Event #{event_type} record" do
        event_attributes = FactoryBot.attributes_for(:event)
        event_attributes[:event_type] = event_type

        allow(Event).to receive(:create!).and_call_original

        expect { RecordEventJob.perform_now(**event_attributes) }.to change { Event.count }.by(1)

        expect(Event).to have_received(:create!).once.with(event_attributes)
      end
    end
  end
end
