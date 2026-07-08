RSpec.describe GIAS::Schools::SchoolPartnerships::Transfer do
  subject(:service) do
    described_class.call(
      object:,
      target_school:,
      period_type:,
      author:
    )
  end

  let(:author) { Events::SystemAuthor.new }
  let(:period_type) { :mentor_at_school_period }

  let(:source_gias_school) { FactoryBot.create(:gias_school, :with_school, name: "Source School") }
  let(:target_gias_school) { FactoryBot.create(:gias_school, :with_school, name: "Target School") }

  let(:source_school) { source_gias_school.school }
  let(:target_school) { target_gias_school.school }

  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership) }

  let!(:source_school_partnership) do
    FactoryBot.create(
      :school_partnership,
      :with_active_lead_provider,
      school: source_school,
      lead_provider_delivery_partnership:
    )
  end

  let(:period) { double("period", school: source_school) }

  let(:object) do
    double(
      "object",
      school_partnership: source_school_partnership,
      mentor_at_school_period: period
    )
  end

  before do
    allow(Events::Record).to receive(:record_school_partnership_recreated_event!)
  end

  context "when reassignment is required" do
    it "creates a school partnership for the target school" do
      expect { service }.to change(::SchoolPartnership, :count).by(1)

      expect(service).to have_attributes(
        school: target_school,
        lead_provider_delivery_partnership:
      )
    end

    it "records a school partnership recreated event" do
      new_school_partnership = service

      expect(Events::Record)
        .to have_received(:record_school_partnership_recreated_event!)
        .with(
          author:,
          old_school_partnership: source_school_partnership,
          new_school_partnership:
        )
    end
  end

  context "when the target school already has a matching partnership" do
    let!(:existing_target_school_partnership) do
      FactoryBot.create(
        :school_partnership,
        school: target_school,
        lead_provider_delivery_partnership:
      )
    end

    it "does not create another school partnership" do
      expect { service }.not_to change(::SchoolPartnership, :count)
    end

    it "returns the existing school partnership" do
      expect(service).to eq(existing_target_school_partnership)
    end

    it "does not record a school partnership recreated event" do
      service

      expect(Events::Record)
        .not_to have_received(:record_school_partnership_recreated_event!)
    end
  end

  context "when the target school has a matching partnership in a different contract year" do
    let(:lead_provider) { source_school_partnership.lead_provider }
    let(:delivery_partner) { source_school_partnership.delivery_partner }

    let(:other_lead_provider_delivery_partnership) do
      FactoryBot.create(
        :lead_provider_delivery_partnership,
        :for_year,
        year: 2023,
        lead_provider:,
        delivery_partner:
      )
    end

    let!(:existing_target_school_partnership) do
      FactoryBot.create(
        :school_partnership,
        school: target_school,
        lead_provider_delivery_partnership: other_lead_provider_delivery_partnership
      )
    end

    it "creates a school partnership for the target school" do
      expect { service }.to change(::SchoolPartnership, :count).by(1)

      expect(service).to have_attributes(
        school: target_school,
        lead_provider_delivery_partnership:
      )
    end

    it "records a school partnership recreated event" do
      new_school_partnership = service

      expect(Events::Record)
        .to have_received(:record_school_partnership_recreated_event!)
        .with(
          author:,
          old_school_partnership: source_school_partnership,
          new_school_partnership:
        )
    end
  end

  context "when the at-school period is already at the target school" do
    let(:source_school) { target_school }

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

  context "when the object has no school partnership" do
    let(:source_school_partnership) { nil }

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

  context "when the target school is nil" do
    let(:target_school) { nil }

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

  context "when the relevant at-school period is nil" do
    let(:period) { nil }

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

  context "when the period type is ect_at_school_period" do
    let(:period_type) { :ect_at_school_period }

    let(:object) do
      double(
        "object",
        school_partnership: source_school_partnership,
        ect_at_school_period: period
      )
    end

    it "uses the ECT at-school period to determine whether reassignment is required" do
      expect { service }.to change(::SchoolPartnership, :count).by(1)

      expect(service).to have_attributes(
        school: target_school,
        lead_provider_delivery_partnership:
      )
    end
  end

  context "when the object does not respond to school_partnership" do
    let(:object) { double("object", mentor_at_school_period: period) }

    it "raises an InvalidObject error" do
      expect { service }.to raise_error(described_class::InvalidObject)
    end
  end

  context "when the period type is not supported" do
    let(:period_type) { :invalid_period }

    it "raises an InvalidPeriodType error" do
      expect { service }.to raise_error(described_class::InvalidPeriodType)
    end
  end

  context "when the object does not respond to the period type" do
    let(:object) do
      double(
        "object",
        school_partnership: source_school_partnership
      )
    end

    it "raises an InvalidPeriodType error" do
      expect { service }.to raise_error(described_class::InvalidPeriodType)
    end
  end
end
