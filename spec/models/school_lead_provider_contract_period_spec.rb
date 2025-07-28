describe SchoolLeadProviderContractPeriod, type: :model do
  describe "enums" do
    let(:expected_choices) { { not_yet_known: "not_yet_known", provider_led: "provider_led", school_led: "school_led" } }

    it { is_expected.to define_enum_for(:training_programme).with_values(expected_choices).backed_by_column_of_type(:text) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:school) }
    it { is_expected.to belong_to(:contract_period) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:school) }
    it { is_expected.to validate_presence_of(:lead_provider) }
    it { is_expected.to validate_presence_of(:contract_period) }
    it { is_expected.to allow_values(true, false).for(:in_partnership) }
    it { is_expected.not_to allow_values(nil, "").for(:in_partnership) }
    it { is_expected.to allow_values(true, false).for(:expression_of_interest) }
    it { is_expected.not_to allow_values(nil, "").for(:expression_of_interest) }
    it { is_expected.to allow_values(*described_class.training_programmes.keys).for(:training_programme) }
  end
end
