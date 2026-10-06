RSpec.describe Region, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:awards).class_name("Region::Award").dependent(:destroy) }
    it { is_expected.to have_one(:active_award).class_name("Region::Award") }
  end

  describe "validations" do
    subject { FactoryBot.build(:region) }

    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to validate_uniqueness_of(:code) }
    it { is_expected.to validate_presence_of(:districts) }
  end

  describe "#district_schools" do
    let(:region) { FactoryBot.create(:region, districts: ["District 8", "District 9"]) }

    def school_in(district, status: :open)
      gias_school = FactoryBot.create(:gias_school, :independent_school_type, :section_41,
                                      status:,
                                      administrative_district_name: district)
      FactoryBot.create(:school, :independent,
                        gias_school:,
                        urn: gias_school.urn)
    end

    it "returns schools whose administrative district falls within the region's districts" do
      school_in("District 7")
      district_8 = school_in("District 8")
      district_9 = school_in("District 9")

      expect(region.district_schools).to contain_exactly(district_8, district_9)
    end

    it "excludes schools that are closed or still proposed to open" do
      school_in("District 6", status: :proposed_to_open)
      school_in("District 7", status: :closed)
      district_8 = school_in("District 8", status: :open)
      district_9 = school_in("District 9", status: :proposed_to_close)

      expect(region.district_schools).to contain_exactly(district_8, district_9)
    end
  end
end
