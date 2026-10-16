RSpec.describe NationalBody do
  describe "associations" do
    subject(:national_body) { FactoryBot.build(:national_body) }

    it { is_expected.to have_many(:appropriate_body_periods) }
  end

  describe "validations" do
    subject(:national_body) do
      FactoryBot.build(:national_body, :istip)
    end

    it { is_expected.to validate_presence_of(:name) }

    it { is_expected.to validate_uniqueness_of(:name) }
  end
end
