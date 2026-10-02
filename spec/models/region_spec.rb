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
end
