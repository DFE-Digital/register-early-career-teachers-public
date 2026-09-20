RSpec.describe Region::Award, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:appropriate_body_period) }
    it { is_expected.to belong_to(:school) }
    it { is_expected.to belong_to(:region) }
  end

  describe "scopes" do
    describe ".active" do
      it "returns lead schools still holding a regional award" do
        active = FactoryBot.create(:region_award)
        FactoryBot.create(:region_award, :deactivated)

        expect(described_class.active).to contain_exactly(active)
      end
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:appropriate_body_period) }
    it { is_expected.to validate_presence_of(:school) }
    it { is_expected.to validate_presence_of(:region) }

    describe "lead school regional awards" do
      let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period, :teaching_school_hub) }
      let(:other_appropriate_body_period) { FactoryBot.create(:appropriate_body_period, :teaching_school_hub) }
      let(:region) { FactoryBot.create(:region) }
      let(:school) { FactoryBot.create(:school) }
      let(:other_school) { FactoryBot.create(:school) }

      it "cannot award a region to a competing active lead school" do
        FactoryBot.create(:region_award, appropriate_body_period:, school:, region:)

        other_award = FactoryBot.build(:region_award,
                                       appropriate_body_period: other_appropriate_body_period,
                                       school: other_school,
                                       region:)

        expect(other_award).not_to be_valid
        expect(other_award.errors[:region_id]).to include("is already linked to an active lead school")
      end

      it "cannot award a region twice within one appropriate body" do
        FactoryBot.create(:region_award, appropriate_body_period:, school:, region:)

        other_award = FactoryBot.build(:region_award,
                                       appropriate_body_period:,
                                       school: other_school,
                                       region:)

        expect(other_award).not_to be_valid
        expect(other_award.errors[:region_id]).to include("is already linked to this appropriate body")
      end

      it "allows a lead school to return to an appropriate body for a region it held before" do
        FactoryBot.create(:region_award, :deactivated, appropriate_body_period:, school:, region:)

        rejoin = FactoryBot.build(:region_award, appropriate_body_period:, school:, region:)

        expect(rejoin).to be_valid
        expect { rejoin.save! }.not_to raise_error
      end

      it "keeps a region's history when it moves between appropriate bodies" do
        FactoryBot.create(:region_award, :deactivated, appropriate_body_period:, school:, region:)
        current = FactoryBot.create(:region_award,
                                    appropriate_body_period: other_appropriate_body_period,
                                    school: other_school,
                                    region:)

        expect(described_class.where(region:).count).to be(2)
        expect(described_class.active).to contain_exactly(current)
      end

      it "allows a lead school to hold several regions at once" do
        award = FactoryBot.create(:region_award, school:, region:)
        other_region = FactoryBot.create(:region)
        FactoryBot.create(:region_award,
                          appropriate_body_period: award.appropriate_body_period,
                          school:,
                          region: other_region)

        expect(school.awarded_regions).to contain_exactly(region, other_region)
      end
    end
  end

  describe "appropriate body associations" do
    it "lists lead schools and regions through the join, collapsing multi-region schools" do
      appropriate_body_period = FactoryBot.create(:appropriate_body_period, :teaching_school_hub)
      school = FactoryBot.create(:school)
      region = FactoryBot.create(:region)
      other_region = FactoryBot.create(:region)

      FactoryBot.create(:region_award, appropriate_body_period:, school:, region:)
      FactoryBot.create(:region_award, appropriate_body_period:, school:, region: other_region)

      expect(appropriate_body_period.lead_schools).to contain_exactly(school)
      expect(appropriate_body_period.regions).to contain_exactly(region, other_region)
    end
  end
end
