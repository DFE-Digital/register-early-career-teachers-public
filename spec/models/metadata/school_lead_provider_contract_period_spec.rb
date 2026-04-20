describe Metadata::SchoolLeadProviderContractPeriod do
  include_context "restricts updates to the Metadata namespace", :school_lead_provider_contract_period_metadata

  describe "declarative touch" do
    let(:target) { FactoryBot.create(:school_contract_period_metadata) }
    let(:instance) do
      FactoryBot.create(:school_lead_provider_contract_period_metadata,
                        school: target.school,
                        contract_period: target.contract_period)
    end

    around do |example|
      Metadata::SchoolLeadProviderContractPeriod.bypass_update_restrictions { example.run }
    end

    it_behaves_like "a declarative touch model", on_event: %i[update], when_changing: %i[expression_of_interest_or_school_partnership], timestamp_attribute: :api_updated_at, target_optional: false
  end

  describe "associations" do
    it { is_expected.to belong_to(:school) }
    it { is_expected.to belong_to(:lead_provider) }
    it { is_expected.to belong_to(:contract_period).with_foreign_key(:contract_period_year) }
    it { is_expected.to have_many(:contract_period_metadata).class_name("Metadata::SchoolContractPeriod").through(:school) }
  end

  describe "validations" do
    subject { FactoryBot.create(:school_lead_provider_contract_period_metadata) }

    it { is_expected.to validate_presence_of(:school) }
    it { is_expected.to validate_presence_of(:lead_provider) }
    it { is_expected.to validate_presence_of(:contract_period) }
    it { is_expected.to allow_values(true, false).for(:expression_of_interest_or_school_partnership) }
    it { is_expected.not_to allow_values(nil, "").for(:expression_of_interest_or_school_partnership) }
    it { is_expected.to validate_uniqueness_of(:school_id).scoped_to(:lead_provider_id, :contract_period_year) }
  end
end
