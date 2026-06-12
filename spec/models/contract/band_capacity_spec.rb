RSpec.describe Contract::BandCapacity, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:active_lead_provider) }
    it { is_expected.to have_many(:contract_banded_fee_structure_bands).class_name("Contract::BandedFeeStructure::Band") }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:min_declarations).with_message("Min declarations is required") }
    it { is_expected.to validate_numericality_of(:min_declarations).is_greater_than(0).only_integer.with_message("Min declarations must be a number greater than zero") }

    it { is_expected.to validate_presence_of(:max_declarations).with_message("Max declarations is required") }
    it { is_expected.to validate_numericality_of(:max_declarations).is_greater_than(:min_declarations).only_integer.with_message("Max declarations must be a number greater than min declarations") }
  end
end
