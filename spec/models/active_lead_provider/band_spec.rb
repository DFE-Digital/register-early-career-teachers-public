RSpec.describe ActiveLeadProvider::Band, type: :model do
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }

  describe "associations" do
    it { is_expected.to belong_to(:active_lead_provider) }
    it { is_expected.to have_many(:terms).class_name("Contract::BandedFeeStructure::Band").inverse_of(:band) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:active_lead_provider).with_message("Choose a lead provider") }

    it { is_expected.to validate_numericality_of(:allocation_order).is_greater_than(0).only_integer.with_message("Allocation order must be a number greater than zero") }

    it { is_expected.to validate_presence_of(:capacity).with_message("Capacity is required") }
    it { is_expected.to validate_numericality_of(:capacity).is_greater_than(0).only_integer.with_message("Capacity must be a number greater than zero") }
  end

  describe "immutability" do
    let!(:first_band) { FactoryBot.create(:active_lead_provider_band, active_lead_provider:) }

    context "with only one band" do
      it "allows changing the capacity of the last band" do
        first_band.update!(capacity: 999)
        expect(first_band.reload.capacity).to eq 999
      end

      it "prevents changing the allocation order of the last band" do
        expect { first_band.update!(allocation_order: 2) }.to raise_error(ActiveRecord::ReadonlyAttributeError)
      end
    end

    context "with multiple bands" do
      let!(:last_band) { FactoryBot.create(:active_lead_provider_band, active_lead_provider:) }

      it "prevents changing the capacity of a band that is not the last" do
        expect { first_band.update!(capacity: 999) }.to raise_error(ActiveRecord::RecordNotSaved, /Only the last band can be updated/)
      end

      it "prevents changing the allocation order of a band that is not the last" do
        expect { first_band.update!(allocation_order: 2) }.to raise_error(ActiveRecord::ReadonlyAttributeError)
      end

      it "allows deleting the last band" do
        expect { last_band.destroy! }.to change(described_class, :count).by(-1)
      end

      it "prevents deleting a band that is not the last" do
        expect { first_band.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed, /Only the last band can be destroyed/)
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

      it "raises a read-only error" do
        expect { band.allocation_order = 2 }.to raise_error(ActiveRecord::ReadonlyAttributeError)
        expect { band.update!(allocation_order: 2) }.to raise_error(ActiveRecord::ReadonlyAttributeError)
      end
    end
  end

  describe "#min_declarations" do
    subject { band.min_declarations }

    context "without allocation_order" do
      let(:band) do
        FactoryBot.build(:active_lead_provider_band,
                         active_lead_provider:,
                         allocation_order: nil)
      end

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
