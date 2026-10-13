RSpec.describe LocalAuthority do
  describe "associations" do
    subject(:local_authority) { FactoryBot.build(:local_authority) }

    it { is_expected.to have_one(:appropriate_body_period) }
  end

  describe "validations" do
    subject(:local_authority) do
      FactoryBot.build(:local_authority)
    end

    it { is_expected.to validate_presence_of(:name) }

    it { is_expected.to validate_uniqueness_of(:name) }
  end
end
