describe LeadProviderDeliveryPartnership do
  describe "associations" do
    it { is_expected.to belong_to(:lead_provider_active_period) }
    it { is_expected.to belong_to(:delivery_partner) }
    it { is_expected.to have_many(:school_partnerships) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:lead_provider_active_period) }
    it { is_expected.to validate_presence_of(:delivery_partner) }
  end
end
