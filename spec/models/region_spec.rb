RSpec.describe Region, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:teaching_school_hub) }
  end

  describe "validations" do
    subject { FactoryBot.build(:region) }

    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to validate_uniqueness_of(:code) }
    it { is_expected.to validate_presence_of(:districts) }
  end
end
