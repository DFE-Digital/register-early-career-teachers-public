describe DeliveryPartner do
  describe "associations" do
    it { is_expected.to have_many(:lead_provider_delivery_partnerships) }
    it { is_expected.to have_many(:events) }
  end

  describe "validations" do
    subject { FactoryBot.build(:delivery_partner) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end
end
