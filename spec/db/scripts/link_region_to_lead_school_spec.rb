require Rails.root.join("db/scripts/link_region_to_lead_school")

RSpec.describe LinkRegionToLeadSchool do
  describe "#call" do
    let!(:region) { FactoryBot.create(:region, code: "EE1") }
    let!(:school) { FactoryBot.create(:school, urn: 136_776) }
    let!(:appropriate_body) { FactoryBot.create(:appropriate_body_period, :teaching_school_hub) }

    let(:lead_schools) do
      [{
        appropriate_body_period_id: appropriate_body.id,
        region_code: "EE1",
        school_urn: 136_776
      }]
    end

    let(:migrator) { described_class.new(lead_schools) }

    it "links the region to its lead school" do
      expect { migrator.call }.to change(TeachingSchoolHub::LeadSchool, :count).by(1)

      expect(TeachingSchoolHub::LeadSchool.find_by(region:)).to be_present
      expect(TeachingSchoolHub::LeadSchool.find_by(school:)).to be_present
      expect(TeachingSchoolHub::LeadSchool.find_by(appropriate_body:)).to be_present
    end

    it "is idempotent" do
      migrator.call

      expect { migrator.call }.not_to change(TeachingSchoolHub::LeadSchool, :count)
    end
  end
end
