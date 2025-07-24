describe Metadata::SchoolLeadProviderContractPeriod do
  include_context "restricts updates to the Metadata namespace", :school_lead_provider_contract_period_metadata

  describe "enums" do
    let(:expected_choices) { { not_yet_known: "not_yet_known", provider_led: "provider_led", school_led: "school_led" } }

    it { is_expected.to define_enum_for(:induction_programme_choice).with_values(expected_choices).backed_by_column_of_type(:enum) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:school) }
    it { is_expected.to belong_to(:contract_period) }
  end

  describe "validations" do
    subject { FactoryBot.create(:school_lead_provider_contract_period_metadata) }

    it { is_expected.to validate_presence_of(:school) }
    it { is_expected.to validate_presence_of(:lead_provider) }
    it { is_expected.to validate_presence_of(:contract_period) }
    it { is_expected.to allow_values(true, false).for(:in_partnership) }
    it { is_expected.not_to allow_values(nil, "").for(:in_partnership) }
    it { is_expected.to allow_values(true, false).for(:expression_of_interest) }
    it { is_expected.not_to allow_values(nil, "").for(:expression_of_interest) }
    it { is_expected.to allow_values(*described_class.induction_programme_choices.keys).for(:induction_programme_choice) }
    it { is_expected.to validate_uniqueness_of(:school_id).scoped_to(:lead_provider_id, :contract_period_id) }
  end
end
