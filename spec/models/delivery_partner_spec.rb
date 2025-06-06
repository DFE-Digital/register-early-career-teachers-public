describe DeliveryPartner do
  describe "associations" do
    it { is_expected.to have_many(:school_partnerships) }
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:available_provider_pairings).inverse_of(:delivery_partner) }
  end

  describe "validations" do
    subject { FactoryBot.build(:delivery_partner) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end
end
