RSpec.describe ActiveLeadProvider::Band, type: :model do
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }

  describe "associations" do
    it { is_expected.to belong_to(:active_lead_provider).required(true) }
    it { is_expected.to have_many(:terms).class_name("Contract::BandedFeeStructure::Band").inverse_of(:band) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:active_lead_provider).with_message("Choose a lead provider") }

    it { is_expected.to validate_numericality_of(:allocation_order).is_greater_than(0).only_integer.with_message("Allocation order must be a number greater than zero") }

    it { is_expected.to validate_presence_of(:capacity).with_message("Capacity is required") }
    it { is_expected.to validate_numericality_of(:capacity).is_greater_than(0).only_integer.with_message("Capacity must be a number greater than zero") }

    describe "#first_band_allocation_order_is_one" do
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
    end
  end

  describe "#allocation_order" do
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

  describe "#editable?" do
    before do
      FactoryBot.create(:active_lead_provider_band, active_lead_provider:)
      FactoryBot.create(:active_lead_provider_band, active_lead_provider:)
    end

    context "when the band is the last band for the active lead provider" do
      subject(:band) { active_lead_provider.bands.last }

      it { is_expected.to be_editable }
    end

    context "when the band is not the last band for the active lead provider" do
      subject(:band) { active_lead_provider.bands.first }

      it { is_expected.not_to be_editable }
    end
  end

  describe "#allocated?" do
    context "when the band is not persisted" do
      subject(:band) { FactoryBot.build(:active_lead_provider_band, active_lead_provider:) }

      it { is_expected.not_to be_allocated }
    end

    context "when the band is persisted" do
      subject(:band) { FactoryBot.create(:active_lead_provider_band, active_lead_provider:) }

      it { is_expected.to be_allocated }
    end
  end

  describe "#first_band?" do
    subject { band.first_band? }

    context "when the band is allocated the first position" do
      let(:band) { FactoryBot.create(:active_lead_provider_band, active_lead_provider:) }

      it { is_expected.to be true }
    end

    context "when unallocated" do
      let(:band) { FactoryBot.build(:active_lead_provider_band, active_lead_provider:) }

      it { is_expected.to be false }
    end

    context "when the band is not first" do
      let(:band) { FactoryBot.build(:active_lead_provider_band, active_lead_provider:) }

      before do
        FactoryBot.create(:active_lead_provider_band, active_lead_provider:)
      end

      it { is_expected.to be false }
    end
  end

  describe "#previous_band" do
    subject { band.previous_band }

    context "when not allocated" do
      let(:band) { FactoryBot.build(:active_lead_provider_band, active_lead_provider:) }

      it { is_expected.to be_nil }
    end

    context "when the band is allocated the first position" do
      let(:band) { FactoryBot.create(:active_lead_provider_band, active_lead_provider:) }

      it { is_expected.to be_nil }
    end

    context "when there are previous bands" do
      before do
        FactoryBot.create(:active_lead_provider_band, active_lead_provider:)
        FactoryBot.create(:active_lead_provider_band, active_lead_provider:, capacity: 123)
      end

      let(:band) { FactoryBot.create(:active_lead_provider_band, active_lead_provider:) }

      it { is_expected.to have_attributes(active_lead_provider:, allocation_order: 2, capacity: 123) }
    end
  end

  describe "#min_declarations" do
    subject { band.min_declarations }

    context "when unallocated" do
      let(:band) { FactoryBot.build(:active_lead_provider_band, active_lead_provider:) }

      it { is_expected.to be_nil }
    end

    context "with the first band" do
      let(:band) { FactoryBot.create(:active_lead_provider_band, active_lead_provider:) }

      it { is_expected.to eq 1 }
    end

    context "with a subsequent band" do
      before do
        FactoryBot.create(:active_lead_provider_band, active_lead_provider:, capacity: 100)
        FactoryBot.create(:active_lead_provider_band, active_lead_provider:, capacity: 50)
      end

      let(:band) { FactoryBot.create(:active_lead_provider_band, active_lead_provider:) }

      it "sums previous capacities plus one" do
        expect(band.min_declarations).to eq 151
      end
    end
  end

  describe "#max_declarations" do
    context "when unallocated" do
      subject { band.max_declarations }

      let(:band) { FactoryBot.build(:active_lead_provider_band, active_lead_provider:) }

      it { is_expected.to be_nil }
    end

    context "with the first band" do
      let(:band) { FactoryBot.create(:active_lead_provider_band, active_lead_provider:, capacity: 100) }

      it "equals the capacity" do
        expect(band.max_declarations).to eq 100
      end
    end

    context "with a subsequent band" do
      before do
        FactoryBot.create(:active_lead_provider_band, active_lead_provider:, capacity: 100)
        FactoryBot.create(:active_lead_provider_band, active_lead_provider:, capacity: 50)
      end

      let(:band) { FactoryBot.create(:active_lead_provider_band, active_lead_provider:, capacity: 200) }

      it "sums all capacities" do
        expect(band.max_declarations).to eq 350
      end
    end
  end
end
