describe LeadProviderDeliveryPartnership do
  describe "associations" do
    it { is_expected.to belong_to(:lead_provider_active_period) }
    it { is_expected.to belong_to(:delivery_partner) }
    it { is_expected.to have_one(:lead_provider).through(:lead_provider_active_period) }
    it { is_expected.to have_one(:registration_period).through(:lead_provider_active_period) }
  end

  describe "validations" do
    subject { build(:lead_provider_delivery_partnership) }

    it { is_expected.to validate_presence_of(:lead_provider_active_period) }
    it { is_expected.to validate_presence_of(:delivery_partner) }
    it { is_expected.to validate_uniqueness_of(:lead_provider_active_period_id).scoped_to(:delivery_partner_id) }
  end
end
