RSpec.describe Contract::BandedFeeStructure::Band, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:banded_fee_structure).class_name("Contract::BandedFeeStructure") }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:min_declarations).with_message("Min declarations is required") }
    it { is_expected.to validate_numericality_of(:min_declarations).is_greater_than(0).only_integer.with_message("Min declarations must be a number greater than zero") }

    it { is_expected.to validate_presence_of(:max_declarations).with_message("Max declarations is required") }
    it { is_expected.to validate_numericality_of(:max_declarations).is_greater_than(:min_declarations).only_integer.with_message("Max declarations must be a number greater than min declarations") }

    it { is_expected.to validate_presence_of(:fee_per_declaration).with_message("Fee per declaration is required") }
    it { is_expected.to validate_numericality_of(:fee_per_declaration).is_greater_than(0).with_message("Fee per declaration must be a number greater than zero") }

    it { is_expected.to validate_presence_of(:output_fee_ratio).with_message("Output fee ratio is required") }
    it { is_expected.to validate_numericality_of(:output_fee_ratio).is_in(0..1).with_message("Output fee ratio must be between 0 and 1") }

    it { is_expected.to validate_presence_of(:service_fee_ratio).with_message("Service fee ratio is required") }
    it { is_expected.to validate_numericality_of(:service_fee_ratio).is_in(0..1).with_message("Service fee ratio must be between 0 and 1") }

    describe "output_fee_ratio + service_fee_ratio" do
      subject(:band) do
        FactoryBot.build_stubbed(
          :contract_banded_fee_structure_band,
          output_fee_ratio:,
          service_fee_ratio:
        )
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

    describe "sequential band declaration boundaries" do
      subject(:band) do
        FactoryBot.build_stubbed(
          :contract_banded_fee_structure_band,
          banded_fee_structure:,
          min_declarations:,
          max_declarations:
        )
      end

      let(:banded_fee_structure) do
        FactoryBot.build_stubbed(
          :contract_banded_fee_structure,
          :with_bands,
          declaration_boundaries: [
            { min: 1, max: 100 },
            { min: 201, max: 300 },
            { min: 101, max: 200 },
          ]
        )
      end

      context "when the band's min declarations is less than the " \
              "previous band's max declarations" do
        let(:min_declarations) { 250 }
        let(:max_declarations) { 400 }

        it { is_expected.to be_invalid }
      end

      context "when the band's min declarations is greater than the " \
              "previous band's max declarations but there is a gap" do
        let(:min_declarations) { 350 }
        let(:max_declarations) { 450 }

        it { is_expected.to be_invalid }
      end

      context "when the band's min declarations is greater than the " \
              "previous band's max declarations and there is no gap" do
        let(:min_declarations) { 301 }
        let(:max_declarations) { 400 }

        it { is_expected.to be_valid }
      end

      context "when the banded fee structure has no bands yet " \
              "and the band's min declarations is not 1" do
        let(:banded_fee_structure) do
          FactoryBot.build_stubbed(:contract_banded_fee_structure)
        end
        let(:min_declarations) { 2 }
        let(:max_declarations) { 400 }

        it { is_expected.to be_invalid }
      end

      context "when the banded fee structure has no bands yet " \
              "and the band's min declarations is 1" do
        let(:banded_fee_structure) do
          FactoryBot.build_stubbed(:contract_banded_fee_structure)
        end
        let(:min_declarations) { 1 }
        let(:max_declarations) { 400 }

        it { is_expected.to be_valid }
      end
    end
  end
end
