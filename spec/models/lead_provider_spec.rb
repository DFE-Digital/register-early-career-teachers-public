describe LeadProvider do
  describe "associations" do
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:active_lead_providers).inverse_of(:lead_provider) }
    it { is_expected.to have_many(:lead_provider_delivery_partnerships).through(:active_lead_providers) }
    it { is_expected.to have_many(:api_tokens).class_name("API::Token") }
  end

  describe "validations" do
    subject { FactoryBot.build(:lead_provider) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive.allow_nil }
  end
end
