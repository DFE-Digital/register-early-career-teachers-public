describe LeadProvider do
  describe "associations" do
    it { is_expected.to have_many(:school_partnerships) }
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:active_lead_providers).inverse_of(:lead_provider) }
    it { is_expected.to have_many(:api_tokens).class_name("API::Token") }
  end

  describe "validations" do
    subject { FactoryBot.build(:lead_provider) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end
end
