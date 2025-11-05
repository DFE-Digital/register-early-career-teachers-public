RSpec.describe TeachingSchoolHub, type: :model do
  let(:lead_school) { FactoryBot.create(:school) }

  describe "associations" do
    it { is_expected.to belong_to(:dfe_sign_in_organisation) }
    it { is_expected.to belong_to(:lead_school) }
    it { is_expected.to have_many(:appropriate_body_periods) }
  end

  describe "validations" do
    subject { FactoryBot.build(:teaching_school_hub, lead_school:) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }

    describe "#lead_school_limit" do
      before do
        FactoryBot.create_list(:teaching_school_hub, 3, lead_school:)
      end

      it "allows up to 3 hubs per lead school" do
        expect(lead_school.led_teaching_school_hubs.count).to eq(3)
      end

      it "prevents more than 3 hubs per lead school" do
        fourth_hub = FactoryBot.build(:teaching_school_hub, lead_school:)

        expect(fourth_hub).not_to be_valid
        expect(fourth_hub.errors[:lead_school]).to include("has reached the maximum of 3 teaching school hubs")
      end
    end
  end

  describe "appropriate_body_periods" do
    subject(:teaching_school_hub) { FactoryBot.create(:teaching_school_hub, lead_school:) }

    # TODO: A TSH can have a multiple periods:
    #   - started and stopped, overlapping and with gaps between
    #   - concurrent active periods provided they are led by different lead schools
    it "can have multiple concurrent appropriate body periods" do
      FactoryBot.create_list(:appropriate_body, 9, teaching_school_hub:)
      expect(teaching_school_hub.appropriate_body_periods.count).to eq(9)
    end
  end
end
