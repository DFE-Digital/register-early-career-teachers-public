RSpec.describe(RecordEventJob) do
  describe "#perform" do
    before { freeze_time }

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

    context "when an 'old' metadata record associated with an Event is destroyed after the job is enqueued" do
      let!(:school_partnership) { FactoryBot.create(:school_partnership) }

      it "creates an Event record without error" do
        event_attributes = FactoryBot.attributes_for(:event)
        event_attributes[:metadata] = { old_school_partnership: school_partnership }

        RecordEventJob.perform_later(**event_attributes)
        school_partnership.destroy!

        perform_enqueued_jobs

        event = Event.last
        expect(event).to have_attributes(**event_attributes.except(:metadata))
        expect(event.metadata[:old_school_partnership]).to be_nil
      end
    end

    context "when a job is enqueued with an `email` attribute" do
      it "creates an Event record without error" do
        event_attributes = FactoryBot.attributes_for(:event)
        event_attributes[:email] = "test@example.com"

        RecordEventJob.perform_later(**event_attributes.except(:author_email))

        perform_enqueued_jobs

        event = Event.last
        expect(event).to have_attributes(**event_attributes.except(:email, :author_email))
        expect(event.author_email).to eq("test@example.com")
      end
    end

    context "when a job is enqueued with a `name` attribute" do
      it "creates an Event record without error" do
        event_attributes = FactoryBot.attributes_for(:event)
        event_attributes[:name] = "A test name"

        RecordEventJob.perform_later(**event_attributes.except(:author_name))

        perform_enqueued_jobs

        event = Event.last
        expect(event).to have_attributes(**event_attributes.except(:name, :author_name))
        expect(event.author_name).to eq("A test name")
      end
    end

    context "when a job is enqueued with a legacy `appropriate_body_id` attribute" do
      let!(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period) }

      it "creates an Event record without error" do
        event_attributes = FactoryBot.attributes_for(:event)
        event_attributes[:appropriate_body_id] = appropriate_body_period.id

        RecordEventJob.perform_later(**event_attributes)

        perform_enqueued_jobs

        event = Event.last
        expect(event).to have_attributes(**event_attributes.except(:appropriate_body_id))
        expect(event.appropriate_body_period).to eq(appropriate_body_period)
      end
    end
  end
end
