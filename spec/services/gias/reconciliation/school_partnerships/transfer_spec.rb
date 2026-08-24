RSpec.describe GIAS::Reconciliation::SchoolPartnerships::Transfer do
  subject(:service) do
    described_class.call(
      predecessor_school_partnership:,
      successor_school:
    )
  end

  let(:author) { Events::SystemAuthor.new }

  let(:predecessor_gias_school) { FactoryBot.create(:gias_school, :with_school, name: "Predecessor School") }
  let(:successor_gias_school) { FactoryBot.create(:gias_school, :with_school, name: "Successor School") }

  let(:predecessor_school) { predecessor_gias_school.school }
  let(:successor_school) { successor_gias_school.school }

  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership) }

  let!(:predecessor_school_partnership) do
    FactoryBot.create(
      :school_partnership,
      :with_framework_agreement,
      school: predecessor_school,
      lead_provider_delivery_partnership:
    )
  end

  before do
    allow(Events::Record).to receive(:record_school_partnership_recreated_event!)
  end

  context "when the object has a related school partnership which doesn't exist at the successor school" do
    it "creates a school partnership for the successor school" do
      expect { service }.to change(::SchoolPartnership, :count).by(1)

      expect(service).to have_attributes(
        school: successor_school,
        lead_provider_delivery_partnership:
      )
    end

    it "records a school partnership recreated event" do
      new_school_partnership = service

      expect(Events::Record)
        .to have_received(:record_school_partnership_recreated_event!)
        .with(
          old_school_partnership: predecessor_school_partnership,
          new_school_partnership:,
          author: an_instance_of(Events::SystemAuthor)
        )
    end
  end

  context "when the object has no school partnership" do
    let(:predecessor_school_partnership) { nil }

    it "does not create a school partnership" do
      expect { service }.not_to change(::SchoolPartnership, :count)
    end

    it "returns nil" do
      expect(service).to be_nil
    end

    it "does not record an event" do
      service

      expect(Events::Record)
        .not_to have_received(:record_school_partnership_recreated_event!)
    end
  end

  context "when the successor school already has a matching partnership" do
    let!(:existing_successor_school_partnership) do
      FactoryBot.create(
        :school_partnership,
        school: successor_school,
        lead_provider_delivery_partnership:
      )
    end

    it "does not create another school partnership" do
      expect { service }.not_to change(::SchoolPartnership, :count)
    end

    it "returns the existing school partnership" do
      expect(service).to eq(existing_successor_school_partnership)
    end

    it "does not record a school partnership recreated event" do
      service

      expect(Events::Record)
        .not_to have_received(:record_school_partnership_recreated_event!)
    end
  end

  context "when the successor school is nil" do
    let(:successor_school) { nil }

    it "does not create a school partnership" do
      expect { service }.not_to change(::SchoolPartnership, :count)
    end

    it "returns nil" do
      expect(service).to be_nil
    end

    it "does not record an event" do
      service

      expect(Events::Record)
        .not_to have_received(:record_school_partnership_recreated_event!)
    end
  end
end
