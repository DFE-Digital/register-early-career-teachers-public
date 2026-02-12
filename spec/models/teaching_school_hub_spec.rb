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

    it { is_expected.to validate_presence_of(:lead_school) }
    it { is_expected.to validate_uniqueness_of(:lead_school) }

    it { is_expected.to validate_presence_of(:dfe_sign_in_organisation) }
    it { is_expected.to validate_uniqueness_of(:dfe_sign_in_organisation) }
  end

  describe "#appropriate_body_periods" do
    subject(:teaching_school_hub) { FactoryBot.create(:teaching_school_hub, lead_school:) }

    # TODO: A TSH can have a multiple periods:
    #   - started and stopped, overlapping and with gaps between
    #   - concurrent active periods provided they are led by different lead schools
    it "can have multiple concurrent appropriate body periods" do
      FactoryBot.create_list(:appropriate_body, 9, teaching_school_hub:)
      expect(teaching_school_hub.appropriate_body_periods.count).to eq(9)
    end
  end

  describe "#districts" do
    subject(:teaching_school_hub) { FactoryBot.create(:teaching_school_hub, lead_school:) }

    before do
      FactoryBot.create_list(:region, 3, teaching_school_hub:)
    end

    it { expect(teaching_school_hub.districts).not_to be_empty }
  end
end
