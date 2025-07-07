describe DeliveryPartner do
  describe "associations" do
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:lead_provider_delivery_partnerships).inverse_of(:delivery_partner) }
    it { is_expected.to have_many(:school_partnerships).through(:lead_provider_delivery_partnerships) }
  end

  describe "validations" do
    subject { build(:delivery_partner) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end
end
