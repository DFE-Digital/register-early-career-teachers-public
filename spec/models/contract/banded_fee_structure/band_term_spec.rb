RSpec.describe Contract::BandedFeeStructure::BandTerm, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:band).class_name("ActiveLeadProvider::Band") }
    it { is_expected.to belong_to(:banded_fee_structure).class_name("Contract::BandedFeeStructure") }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:fee_per_declaration).with_message("Fee per declaration is required") }
    it { is_expected.to validate_numericality_of(:fee_per_declaration).is_greater_than(0).with_message("Fee per declaration must be a number greater than zero") }

    it { is_expected.to validate_presence_of(:output_fee_ratio).with_message("Output fee ratio is required") }
    it { is_expected.to validate_numericality_of(:output_fee_ratio).is_in(0..1).with_message("Output fee ratio must be between 0 and 1") }

    it { is_expected.to validate_presence_of(:service_fee_ratio).with_message("Service fee ratio is required") }
    it { is_expected.to validate_numericality_of(:service_fee_ratio).is_in(0..1).with_message("Service fee ratio must be between 0 and 1") }

    describe "output_fee_ratio + service_fee_ratio" do
      subject(:term) do
        FactoryBot.build_stubbed(:contract_banded_fee_structure_band_term,
                                 output_fee_ratio:,
                                 service_fee_ratio:)
      end

      context "when the sum exceeds 1.0" do
        let(:output_fee_ratio) { 0.60 }
        let(:service_fee_ratio) { 0.41 }

        it { is_expected.to be_invalid }
      end

      context "when the sum is less than 1.0" do
        let(:output_fee_ratio) { 0.60 }
        let(:service_fee_ratio) { 0.39 }

        it { is_expected.to be_invalid }
      end

      context "when the sum is equal to 1.0" do
        let(:output_fee_ratio) { 0.60 }
        let(:service_fee_ratio) { 0.40 }

        it { is_expected.to be_valid }
      end
    end
  end

  describe "#letter" do
    let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }

    let(:banded_fee_structure) do
      FactoryBot.build(:contract_banded_fee_structure,
                       band_terms: [
                         FactoryBot.build(:contract_banded_fee_structure_band_term,
                                          band: active_lead_provider_bands.first),
                         FactoryBot.build(:contract_banded_fee_structure_band_term,
                                          band: active_lead_provider_bands.second),
                         FactoryBot.build(:contract_banded_fee_structure_band_term,
                                          band: active_lead_provider_bands.third),
                         FactoryBot.build(:contract_banded_fee_structure_band_term,
                                          band: active_lead_provider_bands.fourth)
                       ])
    end

    let(:active_lead_provider_bands) do
      FactoryBot.create_list(:active_lead_provider_band, 4,
                             active_lead_provider:)
    end

    it "letters bands alphabetically in boundary order" do
      expect(banded_fee_structure.band_terms.map(&:letter)).to eq(%w[A B C D])
    end
  end
end
