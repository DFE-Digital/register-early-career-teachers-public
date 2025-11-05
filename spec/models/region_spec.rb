RSpec.describe Region, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:teaching_school_hub) }
  end

  describe "validations" do
    subject { FactoryBot.build(:region) }

    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to validate_uniqueness_of(:code) }
    it { is_expected.to validate_presence_of(:districts) }

    describe "#region_limit" do
      let(:teaching_school_hub) do
        FactoryBot.create(:teaching_school_hub, name: "Westeros Academy")
      end

      before do
        FactoryBot.create_list(:region, 3, teaching_school_hub:)
      end

      it "allows up to 3 regions per hub trust" do
        expect(teaching_school_hub.regions.count).to eq(3)
      end

      it "prevents more than 3 regions per hub trust" do
        fourth_region = FactoryBot.build(:region, teaching_school_hub:)

        expect(fourth_region).not_to be_valid
        expect(fourth_region.errors[:teaching_school_hub]).to include("Westeros Academy already has the maximum of 3 hub regions")
      end
    end
  end
end
