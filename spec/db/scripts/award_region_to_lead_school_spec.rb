require Rails.root.join("db/scripts/award_region_to_lead_school")

RSpec.describe AwardRegionToLeadSchool do
  describe "#call" do
    let!(:region) { FactoryBot.create(:region, code: "EE1") }
    let!(:school) { FactoryBot.create(:school, urn: 136_776) }
    let!(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period, :teaching_school_hub) }

    let(:awards) do
      [{
        appropriate_body_period_id: appropriate_body_period.id,
        region_code: "EE1",
        school_urn: 136_776
      }]
    end

    let(:migrator) { described_class.new(awards) }

    it "awards the region to its lead school" do
      expect { migrator.call }.to change(Region::Award, :count).by(1)

      expect(Region::Award.find_by(region:)).to be_present
      expect(Region::Award.find_by(school:)).to be_present
      expect(Region::Award.find_by(appropriate_body_period:)).to be_present
    end

    it "is idempotent" do
      migrator.call

      expect { migrator.call }.not_to change(Region::Award, :count)
    end
  end
end
