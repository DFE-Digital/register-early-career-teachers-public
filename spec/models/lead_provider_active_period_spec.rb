describe LeadProviderActivePeriod do
  describe "associations" do
    it { is_expected.to belong_to(:lead_provider) }
    it { is_expected.to belong_to(:registration_period) }
    it { is_expected.to have_many(:delivery_partnerships).class_name("LeadProviderDeliveryPartnership") }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:lead_provider) }
    it { is_expected.to validate_presence_of(:registration_period) }
  end
end
