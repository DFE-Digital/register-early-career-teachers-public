RSpec.describe Contract::BandedFeeStructure, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:band_terms).class_name("Contract::BandedFeeStructure::BandTerm").inverse_of(:banded_fee_structure).dependent(:destroy) }
    it { is_expected.to belong_to(:contract) }
  end

  describe "validations" do
    subject { FactoryBot.create(:contract).banded_fee_structure }

    it { is_expected.to validate_presence_of(:recruitment_target).with_message("Recruitment target is required") }
    it { is_expected.to validate_numericality_of(:recruitment_target).is_greater_than_or_equal_to(0).only_integer.with_message("Recruitment target must be a number greater than zero") }

    it { is_expected.to validate_presence_of(:uplift_fee_per_declaration).with_message("Uplift fee per declaration is required") }
    it { is_expected.to validate_numericality_of(:uplift_fee_per_declaration).is_greater_than_or_equal_to(0).with_message("Uplift fee per declaration must be greater than or equal to zero") }

    it { is_expected.to validate_numericality_of(:monthly_service_fee).is_greater_than_or_equal_to(0).with_message("Monthly service fee must be greater than or equal to zero").allow_nil }

    it { is_expected.to validate_presence_of(:setup_fee).with_message("Setup fee is required") }
    it { is_expected.to validate_numericality_of(:setup_fee).is_greater_than_or_equal_to(0).with_message("Setup fee must be greater than or equal to zero") }

    it { is_expected.to validate_uniqueness_of(:contract_id).with_message("Contract with the same banded fee structure already exist") }
  end
end
