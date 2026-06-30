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

    describe "#band_belongs_to_contracts_active_lead_provider" do
      subject(:band_term) do
        FactoryBot.create(:contract_banded_fee_structure_band_term,
                          banded_fee_structure: contract.banded_fee_structure,
                          band:)
      end

      let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }
      let!(:contract) { FactoryBot.create(:contract, :for_ecf, active_lead_provider:) }

      context "when the band and contract ALP match" do
        let!(:band) { FactoryBot.create(:active_lead_provider_band, active_lead_provider:) }

        it "is valid" do
          expect(band.active_lead_provider).to eq(contract.active_lead_provider)
          expect(band_term).to be_valid
        end
      end

      context "when the band and contract ALP do not match" do
        let!(:band) { FactoryBot.create(:active_lead_provider_band) }

        it "raises an error" do
          expect(band.active_lead_provider).not_to eq(contract.active_lead_provider)
          expect { band_term }.to raise_error(
            ActiveRecord::RecordInvalid, "Validation failed: Band must belong to the contract's active lead provider"
          )
        end
      end
    end
  end

  describe "delegation" do
    subject(:band_term) { contract.banded_fee_structure.band_terms.first }

    let(:contract) { FactoryBot.create(:contract, :for_ecf, :with_bands_and_band_terms) }

    it "#letter" do
      expect(band_term.letter).to eq(band_term.band.letter)
    end

    it "#min_declarations" do
      expect(band_term.min_declarations).to eq(band_term.band.min_declarations)
    end

    it "#max_declarations" do
      expect(band_term.max_declarations).to eq(band_term.band.max_declarations)
    end

    it "#capacity" do
      expect(band_term.capacity).to eq(band_term.band.capacity)
    end
  end
end
