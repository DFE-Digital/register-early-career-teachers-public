RSpec.describe Contract::Band, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:active_lead_provider) }
    it { is_expected.to have_many(:contract_banded_fee_structure_bands).class_name("Contract::BandedFeeStructure::Band").inverse_of(:contract_band) }
  end

  describe "validations" do
    let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }

    it { is_expected.to validate_presence_of(:allocation_order).with_message("Allocation order is required") }
    it { is_expected.to validate_numericality_of(:allocation_order).is_greater_than(0).only_integer.with_message("Allocation order must be a number greater than zero") }

    it { is_expected.to validate_presence_of(:capacity).with_message("Capacity is required") }
    it { is_expected.to validate_numericality_of(:capacity).is_greater_than(0).only_integer.with_message("Capacity must be a number greater than zero") }

    describe "#allocation_orders_are_sequential_and_contiguous_from_one" do
      subject(:new_band) do
        FactoryBot.build(:contract_band, active_lead_provider:, allocation_order:)
      end

      context "without existing bands" do
        context "and the first band allocation order is 1" do
          let(:allocation_order) { 1 }

          it { is_expected.to be_valid }
        end

        context "and the first band allocation order is not 1" do
          let(:allocation_order) { 2 }

          it "is invalid" do
            expect(new_band).to be_invalid
            expect(new_band.errors[:allocation_order]).to include("The first band's allocation order must be 1")
          end
        end
      end

      context "with existing bands" do
        before do
          FactoryBot.create(:contract_band, active_lead_provider:, allocation_order: 1)
          FactoryBot.create(:contract_band, active_lead_provider:, allocation_order: 2)
        end

        context "when the band allocation order is unique, sequential and contiguous" do
          let(:allocation_order) { 3 }

          it { is_expected.to be_valid }
        end

        context "when the band allocation order is not unique" do
          let(:allocation_order) { 2 }

          it "is invalid" do
            expect(new_band).to be_invalid
            expect(new_band.errors[:allocation_order]).to include("Allocation orders must be sequential without gaps")
          end
        end

        context "when the band allocation order is not sequential" do
          let(:allocation_order) { 4 }

          it "is invalid" do
            expect(new_band).to be_invalid
            expect(new_band.errors[:allocation_order]).to include("Allocation orders must be sequential without gaps")
          end
        end
      end
    end
  end
end
