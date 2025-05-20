describe ActiveLeadProvider do
  describe "associations" do
    it { is_expected.to belong_to(:registration_period) }
    it { is_expected.to belong_to(:lead_provider) }
    it { is_expected.to have_many(:statements) }
  end

  describe "validations" do
    subject { FactoryBot.create(:active_lead_provider) }

    it { is_expected.to validate_presence_of(:lead_provider_id).with_message("Choose a lead provider") }
    it { is_expected.to validate_presence_of(:registration_period_id).with_message("Choose a registration period") }
    it { is_expected.to validate_uniqueness_of(:registration_period_id).scoped_to(:lead_provider_id).with_message("Registration period and lead provider must be unique") }
  end
end
