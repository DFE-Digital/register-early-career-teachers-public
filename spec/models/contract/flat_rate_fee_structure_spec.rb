describe Contract::FlatRateFeeStructure do
  describe "associations" do
    it { is_expected.to belong_to(:contract).optional }
  end

  describe "validations" do
    subject { FactoryBot.build(:contract_flat_rate_fee_structure) }

    it { is_expected.to validate_presence_of(:recruitment_target).with_message("Recruitment target is required") }
    it { is_expected.to validate_presence_of(:fee_per_declaration).with_message("Fee per declaration is required") }
    it { is_expected.to validate_numericality_of(:recruitment_target).only_integer.is_greater_than(0).with_message("Value must be greater than 0") }
    it { is_expected.to validate_numericality_of(:fee_per_declaration).is_greater_than(0).with_message("Amount must be greater than 0") }

    context "uniqueness" do
      subject(:flat_rate_fee_structure) { FactoryBot.create(:contract_flat_rate_fee_structure) }
      let!(:existing_contract_1) { FactoryBot.create(:contract, :for_ittecf_ectp, flat_rate_fee_structure:) }
      let!(:existing_contract_2) { FactoryBot.create(:contract, :for_ittecf_ectp) }

      it "validates that the flat_fee_structure is only used on 1 contract" do
        new_flat_rate_fee_structure = flat_rate_fee_structure.dup
        new_flat_rate_fee_structure.contract = existing_contract_2

        expect(new_flat_rate_fee_structure).not_to be_valid
        expect(new_flat_rate_fee_structure.errors[:contract_id]).to include("Contract with the same flat rate fee structure already exists")
      end
    end
  end
end
