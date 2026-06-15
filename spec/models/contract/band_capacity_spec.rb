RSpec.describe Contract::BandCapacity, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:active_lead_provider) }
    it { is_expected.to have_many(:contract_banded_fee_structure_bands).class_name("Contract::BandedFeeStructure::Band").inverse_of(:contract_band_capacity) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:min_declarations).with_message("Min declarations is required") }
    it { is_expected.to validate_numericality_of(:min_declarations).is_greater_than(0).only_integer.with_message("Min declarations must be a number greater than zero") }

    it { is_expected.to validate_presence_of(:max_declarations).with_message("Max declarations is required") }
    it { is_expected.to validate_numericality_of(:max_declarations).is_greater_than(:min_declarations).only_integer.with_message("Max declarations must be a number greater than min declarations") }

    describe "sequential declaration boundaries" do
      subject(:band_capacity) do
        FactoryBot.build(:contract_band_capacity, active_lead_provider:, min_declarations:, max_declarations:)
      end

      let!(:first_capacity) do
        FactoryBot.create(:contract_band_capacity, active_lead_provider:, min_declarations: 1, max_declarations: 100)
      end

      let!(:second_capacity) do
        FactoryBot.create(:contract_band_capacity, active_lead_provider:, min_declarations: 101, max_declarations: 200)
      end

      let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }

      context "when the capacity's min declarations overlaps the previous capacity's max declarations" do
        let(:min_declarations) { 150 }
        let(:max_declarations) { 400 }

        it "is expected to be invalid" do
          expect(band_capacity).to be_invalid
          expect(band_capacity.errors[:base]).to include("Declaration boundaries must be sequential without gaps")
        end
      end

      context "when the capacity's min declarations is greater than the previous capacity's max declarations but there is a gap" do
        let(:min_declarations) { 250 }
        let(:max_declarations) { 450 }

        it "is expected to be invalid" do
          expect(band_capacity).to be_invalid
          expect(band_capacity.errors[:base]).to include("Declaration boundaries must be sequential without gaps")
        end
      end

      context "when the capacity's min declarations is greater than the previous capacity's max declarations and there is no gap" do
        let(:min_declarations) { 201 }
        let(:max_declarations) { 400 }

        it { is_expected.to be_valid }
      end

      context "when the active lead provider has no capacities yet and the capacity's min declarations is not 1" do
        let!(:first_capacity) { nil }
        let!(:second_capacity) { nil }

        let(:min_declarations) { 2 }
        let(:max_declarations) { 100 }

        it "is expected to be invalid" do
          expect(band_capacity).to be_invalid
          expect(band_capacity.errors[:base]).to include("The first band's min declarations must be 1")
        end
      end

      context "when the active lead provider has no capacities yet and the capacity's min declarations is 1" do
        let!(:first_capacity) { nil }
        let!(:second_capacity) { nil }

        let(:min_declarations) { 1 }
        let(:max_declarations) { 100 }

        it { is_expected.to be_valid }
      end

      context "when updating an existing capacity" do
        let(:banded_fee_structure) { FactoryBot.build(:contract_banded_fee_structure) }

        it "is valid if the updated capacity still has sequential declaration boundaries" do
          second_capacity.max_declarations += 50

          expect(second_capacity).to be_valid
        end

        it "is invalid if the updated capacity no longer has sequential declaration boundaries" do
          second_capacity.min_declarations = 1

          expect(second_capacity).to be_invalid
          expect(second_capacity.errors[:base]).to include("Declaration boundaries must be sequential without gaps")
        end
      end
    end
  end
end
