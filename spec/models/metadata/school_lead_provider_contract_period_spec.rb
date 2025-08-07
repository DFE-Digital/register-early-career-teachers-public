describe Metadata::SchoolLeadProviderContractPeriod do
  include_context "restricts updates to the Metadata namespace", :school_lead_provider_contract_period_metadata

  describe "associations" do
    it { is_expected.to belong_to(:school) }
    it { is_expected.to belong_to(:lead_provider) }
    it { is_expected.to belong_to(:contract_period).with_foreign_key(:contract_period_year) }
  end

  describe "validations" do
    subject { FactoryBot.create(:school_lead_provider_contract_period_metadata) }

    it { is_expected.to validate_presence_of(:school) }
    it { is_expected.to validate_presence_of(:lead_provider) }
    it { is_expected.to validate_presence_of(:contract_period) }
    it { is_expected.to allow_values(true, false).for(:expression_of_interest) }
    it { is_expected.not_to allow_values(nil, "").for(:expression_of_interest) }
    it { is_expected.to validate_uniqueness_of(:school_id).scoped_to(:lead_provider_id, :contract_period_year) }
  end
end
