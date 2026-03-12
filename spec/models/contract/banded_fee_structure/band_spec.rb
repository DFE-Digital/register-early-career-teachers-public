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
        FactoryBot.build(
          :contract_banded_fee_structure_band,
          banded_fee_structure:,
          min_declarations:,
          max_declarations:
        )
      end

      let(:banded_fee_structure) do
        FactoryBot.create(
          :contract_banded_fee_structure,
          :with_bands,
          declaration_boundaries: [
            { min: 1, max: 100 },
            { min: 101, max: 200 },
            { min: 201, max: 300 },
          ]
        )
      end

      context "when the band's min declarations is less than the " \
              "previous band's max declarations" do
        let(:min_declarations) { 250 }
        let(:max_declarations) { 400 }

        it "is expected to be invalid" do
          expect(band).to be_invalid
          expect(band.errors[:base]).to include("Declaration boundaries must be sequential without gaps")
        end
      end

      context "when the band's min declarations is greater than the " \
              "previous band's max declarations but there is a gap" do
        let(:min_declarations) { 350 }
        let(:max_declarations) { 450 }

        it "is expected to be invalid" do
          expect(band).to be_invalid
          expect(band.errors[:base]).to include("Declaration boundaries must be sequential without gaps")
        end
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

        it "is expected to be invalid" do
          expect(band).to be_invalid
          expect(band.errors[:min_declarations]).to include("The first band's min declarations must be 1")
        end
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

      context "when updating an existing band" do
        let(:banded_fee_structure) { FactoryBot.create(:contract_banded_fee_structure, :with_bands) }

        it "is valid if the updated band still has sequential declaration boundaries" do
          band = banded_fee_structure.bands.last
          band.max_declarations += 50

          expect(band).to be_valid
        end

        it "is invalid if the updated band no longer has sequential declaration boundaries" do
          band = banded_fee_structure.bands.last
          band.min_declarations = 1

          expect(band).to be_invalid
          expect(band.errors[:base]).to include("Declaration boundaries must be sequential without gaps")
        end
      end
    end

    describe "band consistency across active lead providers" do
      let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }

      it "is valid when creating the first band for the active lead provider" do
        contract = FactoryBot.create(:contract, :for_ecf, active_lead_provider:)
        banded_fee_structure = FactoryBot.create(:contract_banded_fee_structure, contract:)
        band = FactoryBot.build(:contract_banded_fee_structure_band, banded_fee_structure:)
        expect(band).to be_valid
      end

      it "is valid when creating bands for another contract for the same active lead provider when the bands are consistent" do
        original_contract = FactoryBot.create(:contract, :for_ecf, active_lead_provider:)
        banded_fee_structure = FactoryBot.create(:contract_banded_fee_structure, contract: original_contract)
        FactoryBot.create(:contract_banded_fee_structure_band, banded_fee_structure:, fee_per_declaration: 100)

        new_contract = FactoryBot.create(:contract, :for_ecf, active_lead_provider:)
        new_banded_fee_structure = FactoryBot.create(:contract_banded_fee_structure, contract: new_contract)
        new_band = FactoryBot.build(:contract_banded_fee_structure_band, banded_fee_structure: new_banded_fee_structure, fee_per_declaration: 100)

        expect(new_band).to be_valid
      end

      it "is invalid when creating bands for another contract for the same active lead provider when the bands are not consistent" do
        original_contract = FactoryBot.create(:contract, :for_ecf, active_lead_provider:)
        banded_fee_structure = FactoryBot.create(:contract_banded_fee_structure, contract: original_contract)
        FactoryBot.create(:contract_banded_fee_structure_band, banded_fee_structure:, fee_per_declaration: 100, min_declarations: 1, max_declarations: 2)
        FactoryBot.create(:contract_banded_fee_structure_band, banded_fee_structure:, fee_per_declaration: 150, min_declarations: 3, max_declarations: 4)

        new_contract = FactoryBot.create(:contract, :for_ecf, active_lead_provider:)
        new_banded_fee_structure = FactoryBot.create(:contract_banded_fee_structure, contract: new_contract)
        new_band = FactoryBot.build(:contract_banded_fee_structure_band, banded_fee_structure: new_banded_fee_structure, fee_per_declaration: 150, min_declarations: 1, max_declarations: 2)

        expect(new_band).to be_invalid
        expect(new_band.errors[:base]).to include(/Band at index 0 is inconsistent across statements for the same active lead provider/)

        new_band.fee_per_declaration = 100
        expect(new_band).to be_valid
        new_band.save!

        new_band = FactoryBot.build(:contract_banded_fee_structure_band, banded_fee_structure: new_banded_fee_structure, fee_per_declaration: 150, min_declarations: 3, max_declarations: 5)
        expect(new_band).to be_invalid
        expect(new_band.errors[:base]).to include(/Band at index 1 is inconsistent across statements for the same active lead provider/)

        new_band.max_declarations = 4
        expect(new_band).to be_valid
      end

      it "is invalid when updating a band such that it becomes inconsistent with bands for the same active lead provider" do
        original_contract = FactoryBot.create(:contract, :for_ecf, active_lead_provider:)
        banded_fee_structure = FactoryBot.create(:contract_banded_fee_structure, contract: original_contract)
        FactoryBot.create(:contract_banded_fee_structure_band, banded_fee_structure:, fee_per_declaration: 100)

        new_contract = FactoryBot.create(:contract, :for_ecf, active_lead_provider:)
        new_banded_fee_structure = FactoryBot.create(:contract_banded_fee_structure, contract: new_contract)
        new_band = FactoryBot.create(:contract_banded_fee_structure_band, banded_fee_structure: new_banded_fee_structure, fee_per_declaration: 100)

        new_band.fee_per_declaration = 150

        expect(new_band).to be_invalid
        expect(new_band.errors[:base]).to include(/Band at index 0 is inconsistent across statements for the same active lead provider/)

        new_band.fee_per_declaration = 100
        expect(new_band).to be_valid
      end
    end
  end

  describe "#capacity" do
    it "returns max_declarations - min_declarations + 1" do
      band = FactoryBot.build_stubbed(:contract_banded_fee_structure_band, min_declarations: 1, max_declarations: 100)
      expect(band.capacity).to eq(100)
    end
  end
end
