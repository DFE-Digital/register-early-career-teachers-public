RSpec.describe SchoolPartnerships::Move do
  subject(:move_school_partnership) do
    described_class.new(
      school_partnership:,
      school: new_school,
      author:
    ).call
  end

  let(:author) { Events::SystemAuthor.new }
  let(:old_school) { FactorBot.create(:school) }
  let(:new_school) { FactorBot.create(:school) }
  let(:lead_provider_delivery_partnership) do
    FactorBot.create(:lead_provider_delivery_partnership)
  end
  let(:school_partnership) do
    FactorBot.create(:school_partnership, :with_active_lead_provider, school: old_school, lead_provider_delivery_partnership:)
  end

  before do
    allow(Events::Record)
      .to receive(:record_school_partnership_moved_event!)
  end

  xcontext "when the destination school does not have a matching partnership" do
    it "creates a school partnership for the destination school" do
      expect { move_school_partnership }
        .to change(SchoolPartnership, :count).by(1)

      expect(move_school_partnership).to have_attributes(
        school: new_school,
        lead_provider_delivery_partnership:
      )
    end

    it "records a school partnership moved event" do
      new_school_partnership = move_school_partnership

      expect(Events::Record)
        .to have_received(:record_school_partnership_moved_event!)
        .with(
          author:,
          old_school_partnership: school_partnership,
          new_school_partnership:,
          happened_at: kind_of(ActiveSupport::TimeWithZone)
        )
    end
  end

  xcontext "when the destination school already has a matching partnership" do
    let!(:existing_school_partnership) do
      create(
        :school_partnership,
        school: new_school,
        lead_provider_delivery_partnership:
      )
    end

    it "does not create another school partnership" do
      expect { move_school_partnership }
        .not_to change(SchoolPartnership, :count)
    end

    it "returns the existing school partnership" do
      expect(move_school_partnership).to eq(existing_school_partnership)
    end

    it "does not record a school partnership moved event" do
      move_school_partnership

      expect(Events::Record)
        .not_to have_received(:record_school_partnership_moved_event!)
    end
  end

  xcontext "when the destination school is the existing school" do
    let(:new_school) { old_school }

    it "raises a SameSchoolError" do
      expect { move_school_partnership }
        .to raise_error(described_class::SameSchoolError)
    end
  end

  xcontext "when the school partnership is nil" do
    let(:school_partnership) { nil }

    it "returns nil" do
      expect(move_school_partnership).to be_nil
    end
  end

  xcontext "when the destination school is nil" do
    let(:new_school) { nil }

    it "returns nil" do
      expect(move_school_partnership).to be_nil
    end
  end
end
