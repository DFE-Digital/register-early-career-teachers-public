RSpec.describe(RecordEventJob) do
  describe "#perform" do
    Event::EVENT_TYPES.each do |event_type|
      it "creates an Event #{event_type} record" do
        event_attributes = FactoryBot.attributes_for(:event)
        event_attributes[:event_type] = event_type

        allow(Event).to receive(:create!).and_call_original

        expect { RecordEventJob.perform_now(**event_attributes) }.to change { Event.count }.by(1)

        expect(Event).to have_received(:create!).once.with(event_attributes)
      end
    end

    context "when a record associated with an Event is destroyed after the job is enqueued" do
      let!(:teacher) { FactoryBot.create(:teacher) }

      before { freeze_time }

      it "creates an Event record without error" do
        event_attributes = FactoryBot.attributes_for(:event)
        event_attributes[:teacher] = teacher

        RecordEventJob.perform_later(**event_attributes)
        teacher.destroy!

        perform_enqueued_jobs

        event = Event.last
        expect(event).to have_attributes(**event_attributes.except(:teacher))
        expect(event.teacher).to be_nil
      end
    end
  end
end
