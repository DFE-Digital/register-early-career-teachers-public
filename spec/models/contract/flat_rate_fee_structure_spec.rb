describe Contract::FlatRateFeeStructure do
  describe "associations" do
    it { is_expected.to have_many(:contracts).with_foreign_key("contract_flat_rate_fee_structure_id").inverse_of(:contract_flat_rate_fee_structure) }
  end

  describe "validations" do
    subject { FactoryBot.build(:contract_flat_rate_fee_structure) }

    it { is_expected.to validate_presence_of(:recruitment_target).with_message("Recruitment target is required") }
    it { is_expected.to validate_presence_of(:fee_per_declaration).with_message("Fee per declaration is required") }
    it { is_expected.to validate_numericality_of(:recruitment_target).only_integer.is_greater_than(0).with_message("Value must be greater than 0") }
    it { is_expected.to validate_numericality_of(:fee_per_declaration).is_greater_than(0).with_message("Amount must be greater than 0") }
  end
end
