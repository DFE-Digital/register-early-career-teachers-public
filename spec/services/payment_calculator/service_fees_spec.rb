RSpec.describe PaymentCalculator::ServiceFees do
  subject(:service_fees) { described_class.new(banded_fee_structure:) }

  describe "#monthly_amount" do
    context "with a single band" do
      let(:banded_fee_structure) do
        FactoryBot.create(
          :contract_banded_fee_structure,
          :with_bands,
          recruitment_target: 100,
          declaration_boundaries: [{ min: 1, max: 200 }]
        )
      end

      it "calculates monthly service fee from the band" do
        band = banded_fee_structure.bands.first
        filled = [100, band.capacity].min
        expected = (filled * band.fee_per_declaration * band.service_fee_ratio) / 29

        expect(service_fees.monthly_amount).to eq(expected)
      end
    end

    context "with multiple bands" do
      let(:banded_fee_structure) do
        FactoryBot.create(
          :contract_banded_fee_structure,
          :with_bands,
          recruitment_target: 150,
          declaration_boundaries: [{ min: 1, max: 100 }, { min: 101, max: 200 }]
        )
      end

      it "fills bands in order up to the recruitment target" do
        bands = banded_fee_structure.bands.order(:min_declarations)
        band1 = bands.first
        band2 = bands.second

        filled1 = [150, band1.capacity].min
        filled2 = [150 - filled1, band2.capacity].min

        expected_total = (filled1 * band1.fee_per_declaration * band1.service_fee_ratio) +
          (filled2 * band2.fee_per_declaration * band2.service_fee_ratio)

        expect(service_fees.monthly_amount).to eq(expected_total / 29)
      end
    end

    context "when recruitment target is less than first band capacity" do
      let(:banded_fee_structure) do
        FactoryBot.create(
          :contract_banded_fee_structure,
          :with_bands,
          recruitment_target: 50,
          declaration_boundaries: [{ min: 1, max: 200 }]
        )
      end

      it "only fills up to the recruitment target" do
        band = banded_fee_structure.bands.first
        expected = (50 * band.fee_per_declaration * band.service_fee_ratio) / 29

        expect(service_fees.monthly_amount).to eq(expected)
      end
    end
  end
end
