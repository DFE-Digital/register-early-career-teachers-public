RSpec.describe PaymentCalculator::ServiceFees do
  subject(:service_fees) { described_class.new(banded_fee_structure: banded_fee_structure.reload) }

  describe "#monthly_amount" do
    context "with a single band" do
      let(:banded_fee_structure) do
        FactoryBot.create(
          :contract_banded_fee_structure,
          recruitment_target: 100,
          setup_fee: 500
        )
      end
      let!(:band) do
        FactoryBot.create(
          :contract_banded_fee_structure_band,
          banded_fee_structure:,
          min_declarations: 1,
          max_declarations: 100,
          fee_per_declaration: 800,
          service_fee_ratio: 0.40,
          output_fee_ratio: 0.60
        )
      end

      it "returns (band_totals - setup_fee_deduction) / 29" do
        # band_totals:         100 * 800 * 0.40 = 32,000
        # setup_fee_deduction: 100 * 500 / 100  = 500
        # total:               32,000 - 500 = 31,500
        # monthly:             31,500 / 29
        expect(service_fees.monthly_amount).to eq(31_500.to_d / 29)
      end
    end

    context "with multiple bands" do
      let(:banded_fee_structure) do
        FactoryBot.create(
          :contract_banded_fee_structure,
          recruitment_target: 150,
          setup_fee: 500
        )
      end
      let!(:band_a) do
        FactoryBot.create(
          :contract_banded_fee_structure_band,
          banded_fee_structure:,
          min_declarations: 1,
          max_declarations: 100,
          fee_per_declaration: 800,
          service_fee_ratio: 0.40,
          output_fee_ratio: 0.60
        )
      end
      let!(:band_b) do
        banded_fee_structure.bands.reset
        FactoryBot.create(
          :contract_banded_fee_structure_band,
          banded_fee_structure:,
          min_declarations: 101,
          max_declarations: 200,
          fee_per_declaration: 600,
          service_fee_ratio: 0.40,
          output_fee_ratio: 0.60
        )
      end

      it "deducts setup fee from first band only" do
        # band_totals:         (100 * 800 * 0.40) + (50 * 600 * 0.40) = 32,000 + 12,000 = 44,000
        # setup_fee_deduction: 100 * 500 / 100 = 500
        # total:               44,000 - 500 = 43,500
        # monthly:             43,500 / 29
        expect(service_fees.monthly_amount).to eq(43_500.to_d / 29)
      end
    end

    context "when recruitment target is less than first band capacity" do
      let(:banded_fee_structure) do
        FactoryBot.create(
          :contract_banded_fee_structure,
          recruitment_target: 50,
          setup_fee: 500
        )
      end
      let!(:band) do
        FactoryBot.create(
          :contract_banded_fee_structure_band,
          banded_fee_structure:,
          min_declarations: 1,
          max_declarations: 100,
          fee_per_declaration: 800,
          service_fee_ratio: 0.40,
          output_fee_ratio: 0.60
        )
      end

      it "deducts setup fee proportionally to filled slots" do
        # band_totals:         50 * 800 * 0.40 = 16,000
        # setup_fee_deduction: 50 * 500 / 100  = 250 (not full 500)
        # total:               16,000 - 250 = 15,750
        # monthly:             15,750 / 29
        expect(service_fees.monthly_amount).to eq(15_750.to_d / 29)
      end
    end
  end
end
