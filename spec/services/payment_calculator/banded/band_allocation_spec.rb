RSpec.describe PaymentCalculator::Banded::BandAllocation do
  subject(:allocation) { described_class.new(band:, declaration_type: "started") }

  let(:band) do
    FactoryBot.build_stubbed(
      :contract_banded_fee_structure_band,
      min_declarations: 1,
      max_declarations: 100
    )
  end

  describe "#capacity" do
    it "returns the inclusive range size of the band" do
      expect(allocation.capacity).to eq(100)
    end
  end

  describe "#net_billable_count" do
    it "returns zero when all counts are zero" do
      expect(allocation.net_billable_count).to eq(0)
    end

    it "returns previous_billable_count when only that is set" do
      allocation.add_previous_billable(40)
      expect(allocation.net_billable_count).to eq(40)
    end

    it "sums billable and subtracts refundable" do
      allocation.add_previous_billable(40)
      allocation.add_billable(20)
      allocation.remove_previous_refundable(5)
      allocation.remove_refundable(10)

      expect(allocation.net_billable_count).to eq(45)
    end

    it "clamps refundable to net billable so it cannot go negative" do
      allocation.add_previous_billable(10)
      allocation.remove_refundable(20)

      expect(allocation.refundable_count).to eq(10)
      expect(allocation.net_billable_count).to eq(0)
    end
  end

  describe "#available_capacity" do
    it "returns full capacity when no declarations allocated" do
      expect(allocation.available_capacity).to eq(100)
    end

    it "returns remaining capacity after billable allocations" do
      allocation.add_previous_billable(60)
      allocation.add_billable(20)

      expect(allocation.available_capacity).to eq(20)
    end

    it "floors at zero when capacity is exceeded" do
      allocation.add_previous_billable(100)

      expect(allocation.available_capacity).to eq(0)
    end

    it "increases when refunds reduce net_billable_count" do
      allocation.add_previous_billable(80)
      allocation.remove_previous_refundable(30)

      expect(allocation.available_capacity).to eq(50)
    end
  end

  describe "#declaration_type" do
    it "returns the declaration type" do
      expect(allocation.declaration_type).to eq("started")
    end
  end

  describe "initial state" do
    it "starts with all counts at zero" do
      expect(allocation).to have_attributes(
        previous_billable_count: 0,
        previous_refundable_count: 0,
        billable_count: 0,
        refundable_count: 0
      )
    end
  end
end
