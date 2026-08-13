RSpec.describe Contract::BandedFeeStructure::BandTerm, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:band).class_name("FrameworkAgreement::Band") }
    it { is_expected.to belong_to(:banded_fee_structure).class_name("Contract::BandedFeeStructure") }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:fee_per_declaration).with_message("Fee per declaration is required") }
    it { is_expected.to validate_numericality_of(:fee_per_declaration).is_greater_than(0).with_message("Fee per declaration must be a number greater than zero") }

    describe "service_fee_ratio" do
      subject(:band_term) { FactoryBot.build_stubbed(:contract_banded_fee_structure_band_term) }

      it "is required once an output fee has been set" do
        band_term.service_fee_ratio = nil
        expect(band_term).to be_invalid
        expect(band_term.errors[:service_fee_ratio]).to eq(["Service fee ratio is required"])
      end
    end

    describe "output_fee_percentage" do
      subject(:band_term) { FactoryBot.build_stubbed(:contract_banded_fee_structure_band_term) }

      it "must be present and between 0 and 100, reporting against the field the user filled in" do
        band_term.output_fee_percentage = nil
        expect(band_term).to be_invalid
        expect(band_term.errors[:output_fee_percentage]).to eq(["Output fee percentage is required"])

        band_term.output_fee_percentage = 150
        expect(band_term).to be_invalid
        expect(band_term.errors[:output_fee_percentage]).to eq(["Output fee percentage must be between 0 and 100"])

        band_term.output_fee_percentage = 60
        expect(band_term).to be_valid
      end
    end

    describe "output_fee_ratio + service_fee_ratio" do
      subject(:band_term) do
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

    describe "#band_belongs_to_contracts_framework_agreement" do
      subject(:band_term) do
        FactoryBot.create(:contract_banded_fee_structure_band_term,
                          banded_fee_structure: contract.banded_fee_structure,
                          band:)
      end

      let(:framework_agreement) { FactoryBot.create(:framework_agreement) }
      let!(:contract) { FactoryBot.create(:contract, :for_ecf, framework_agreement:) }

      context "when the band and contract ALP match" do
        let!(:band) { FactoryBot.create(:framework_agreement_band, framework_agreement:) }

        it "is valid" do
          expect(band.framework_agreement).to eq(contract.framework_agreement)
          expect(band_term).to be_valid
        end
      end

      context "when the band and contract ALP do not match" do
        let!(:band) { FactoryBot.create(:framework_agreement_band) }

        it "raises an error" do
          expect(band.framework_agreement).not_to eq(contract.framework_agreement)
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

  describe "percentages" do
    subject(:band_term) do
      FactoryBot.build(:contract_banded_fee_structure_band_term,
                       output_fee_ratio: 0.123,
                       service_fee_ratio: 0.456)
    end

    describe "#output_fee_percentage" do
      it "converts and rounds output_fee_ratio" do
        expect(band_term.output_fee_percentage).to eq(12)
      end
    end

    describe "#output_fee_percentage=" do
      it "overrides and rounds output_fee_ratio and derives service_fee_ratio" do
        band_term.output_fee_percentage = 34.56
        expect(band_term.output_fee_ratio.to_f).to eq(0.35)
        expect(band_term.service_fee_ratio.to_f).to eq(0.65)

        band_term.output_fee_percentage = nil
        expect(band_term.output_fee_ratio).to be_nil
        expect(band_term.service_fee_ratio).to be_nil
      end
    end

    describe "#service_fee_percentage" do
      it "converts and rounds service_fee_ratio" do
        expect(band_term.service_fee_percentage).to eq(46)
      end
    end
  end
end
