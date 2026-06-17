RSpec.describe ActiveLeadProvider::Band, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:active_lead_provider).required(true) }
    it { is_expected.to have_many(:terms).class_name("Contract::BandedFeeStructure::Band").inverse_of(:band) }
  end

  describe "validations" do
    let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }

    it { is_expected.to validate_presence_of(:active_lead_provider).with_message("Choose a lead provider") }

    it { is_expected.to validate_numericality_of(:allocation_order).is_greater_than(0).only_integer.with_message("Allocation order must be a number greater than zero") }

    it { is_expected.to validate_presence_of(:capacity).with_message("Capacity is required") }
    it { is_expected.to validate_numericality_of(:capacity).is_greater_than(0).only_integer.with_message("Capacity must be a number greater than zero") }

    describe "#allocation_orders_are_sequential_and_contiguous_from_one" do
      subject(:band) do
        FactoryBot.build(:active_lead_provider_band, active_lead_provider:, allocation_order:)
      end

      context "without existing bands" do
        context "and the first band allocation order is 1" do
          let(:allocation_order) { 1 }

          it { is_expected.to be_valid }
        end

        context "and the first band allocation order is not 1" do
          let(:allocation_order) { 2 }

          it "is invalid" do
            expect(band).to be_invalid
            expect(band.errors[:allocation_order]).to include("The first band's allocation order must be 1")
          end
        end
      end

      context "with existing bands" do
        before do
          FactoryBot.create(:active_lead_provider_band, active_lead_provider:, allocation_order: 1)
          FactoryBot.create(:active_lead_provider_band, active_lead_provider:, allocation_order: 2)
        end

        context "when the band allocation order is unique, sequential and contiguous" do
          let(:allocation_order) { 3 }

          it { is_expected.to be_valid }
        end

        context "when the band allocation order is not unique" do
          let(:allocation_order) { 2 }

          it "is invalid" do
            expect(band).to be_invalid
            expect(band.errors[:allocation_order]).to contain_exactly("The allocation order should be 3")
          end
        end

        context "when the band allocation order is not sequential" do
          let(:allocation_order) { 4 }

          it "is invalid" do
            expect(band).to be_invalid
            expect(band.errors[:allocation_order]).to contain_exactly("The allocation order should be 3")
          end
        end
      end
    end
  end

  describe "#allocation_order" do
    let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }

    it "auto-assigns the next position" do
      expect(FactoryBot.create(:active_lead_provider_band, active_lead_provider:).allocation_order).to eq 1
      expect(FactoryBot.create(:active_lead_provider_band, active_lead_provider:).allocation_order).to eq 2
      expect(FactoryBot.create(:active_lead_provider_band, active_lead_provider:).allocation_order).to eq 3
    end

    context "when the allocation order of a persisted band is edited" do
      subject(:band) do
        FactoryBot.create(:active_lead_provider_band, active_lead_provider:)
      end

      it do
        expect { band.allocation_order = 2 }.to raise_error(ActiveRecord::ReadonlyAttributeError)
      end
    end
  end
end
