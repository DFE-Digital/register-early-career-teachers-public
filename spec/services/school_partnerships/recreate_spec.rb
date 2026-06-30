RSpec.describe SchoolPartnerships::Recreate do
  subject(:recreate_school_partnership) do
    described_class.new(
      school_partnership:,
      school: new_school,
      author:
    ).call
  end

  let(:author) { Events::SystemAuthor.new }
  let(:old_gias_school) { FactoryBot.create(:gias_school, :with_school, name: "Old School") }
  let(:new_gias_school) { FactoryBot.create(:gias_school, :with_school, name: "New School") }
  let(:old_school) { old_gias_school.school }
  let(:new_school) { new_gias_school.school }
  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership) }
  let!(:school_partnership) do
    FactoryBot.create(:school_partnership, :with_active_lead_provider, school: old_school, lead_provider_delivery_partnership:)
  end

  before do
    allow(Events::Record).to receive(:record_school_partnership_recreated_event!)
  end

  context "when the destination school does not have a matching partnership" do
    it "creates a school partnership for the destination school" do
      expect { recreate_school_partnership }.to change(SchoolPartnership, :count).by(1)

      expect(recreate_school_partnership).to have_attributes(
        school: new_school,
        lead_provider_delivery_partnership:
      )
    end

    it "records a school partnership recreated event" do
      new_school_partnership = recreate_school_partnership

      expect(Events::Record)
        .to have_received(:record_school_partnership_recreated_event!)
        .with(
          author:,
          old_school_partnership: school_partnership,
          new_school_partnership:
        )
    end
  end

  context "when the destination school already has a matching partnership" do
    let!(:existing_school_partnership) { FactoryBot.create(:school_partnership, school: new_school, lead_provider_delivery_partnership:) }

    it "does not create another school partnership" do
      expect { recreate_school_partnership }.not_to change(SchoolPartnership, :count)
    end

    it "returns the existing school partnership" do
      expect(recreate_school_partnership).to eq(existing_school_partnership)
    end

    it "does not record a school partnership recreated event" do
      recreate_school_partnership

      expect(Events::Record).not_to have_received(:record_school_partnership_recreated_event!)
    end
  end

  context "when the destination school has a matching partnership in a different contract year" do
    let(:lead_provider) { school_partnership.lead_provider }
    let(:delivery_partner) { school_partnership.delivery_partner }
    let(:other_lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, :for_year, year: 2023, lead_provider:, delivery_partner:) }

    let!(:existing_school_partnership) { FactoryBot.create(:school_partnership, school: new_school, lead_provider_delivery_partnership: other_lead_provider_delivery_partnership) }

    it "creates a school partnership for the destination school" do
      expect { recreate_school_partnership }.to change(SchoolPartnership, :count).by(1)

      expect(recreate_school_partnership).to have_attributes(
        school: new_school,
        lead_provider_delivery_partnership:
      )
    end

    it "records a school partnership recreated event" do
      new_school_partnership = recreate_school_partnership

      expect(Events::Record)
        .to have_received(:record_school_partnership_recreated_event!)
        .with(
          author:,
          old_school_partnership: school_partnership,
          new_school_partnership:
        )
    end
  end

  context "when the destination school is the existing school" do
    let(:new_school) { old_school }

    it "raises a SameSchoolError" do
      expect { recreate_school_partnership }.to raise_error(described_class::SameSchoolError)
    end
  end

  context "when the school partnership is nil" do
    let(:school_partnership) { nil }

    it "returns nil" do
      expect(recreate_school_partnership).to be_nil
    end
  end

  context "when the destination school is nil" do
    let(:new_school) { nil }

    it "returns nil" do
      expect(recreate_school_partnership).to be_nil
    end
  end
end
