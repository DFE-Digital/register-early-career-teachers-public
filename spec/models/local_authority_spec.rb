RSpec.describe LocalAuthority do
  describe "validations" do
    subject(:local_authority) do
      FactoryBot.build(:local_authority)
    end

    it { is_expected.to validate_presence_of(:name) }

    it { is_expected.to validate_uniqueness_of(:name) }
  end
end
