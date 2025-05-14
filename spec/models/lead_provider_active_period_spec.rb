describe LeadProviderActivePeriod do
  describe "associations" do
    it { is_expected.to belong_to(:lead_provider) }
    it { is_expected.to belong_to(:registration_period) }
    it { is_expected.to have_many(:delivery_partnerships).class_name("LeadProviderDeliveryPartnership") }
    it { is_expected.to have_many(:expressions_of_interest).class_name("TrainingPeriod").inverse_of(:expression_of_interest) }
    it { is_expected.to have_many(:statements) }
  end

  describe "validations" do
    subject { build(:lead_provider_active_period) }

    it { is_expected.to validate_presence_of(:lead_provider) }
    it { is_expected.to validate_presence_of(:registration_period) }
    it { is_expected.to validate_uniqueness_of(:registration_period_id).scoped_to(:lead_provider_id) }
  end
end
