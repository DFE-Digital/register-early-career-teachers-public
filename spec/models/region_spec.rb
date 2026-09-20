RSpec.describe Region, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:teaching_school_hub_lead_schools) }
    it { is_expected.to have_one(:active_teaching_school_hub_lead_school) }
  end

  describe "validations" do
    subject { FactoryBot.build(:region) }

    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to validate_uniqueness_of(:code) }
    it { is_expected.to validate_presence_of(:districts) }
  end
end
