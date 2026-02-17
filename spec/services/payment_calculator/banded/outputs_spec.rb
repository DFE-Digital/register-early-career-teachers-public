RSpec.describe PaymentCalculator::Banded::Outputs do
  subject(:outputs) do
    described_class.new(
      declarations:,
      previous_declarations:,
      banded_fee_structure:
    )
  end

  let(:previous_declarations) { Declaration.payment_status_no_payment.limit(5) }
  let(:declarations) { Declaration.where.not(id: previous_declarations.pluck(:id)) }
  let(:banded_fee_structure) { FactoryBot.create(:contract_banded_fee_structure) }
  let!(:band_a) { FactoryBot.create(:contract_banded_fee_structure_band, banded_fee_structure:, min_declarations: 1, max_declarations: 20, fee_per_declaration: 100.0) }
  let!(:band_b) { FactoryBot.create(:contract_banded_fee_structure_band, banded_fee_structure:, min_declarations: 21, max_declarations: 40, fee_per_declaration: 100.0) }
  let!(:band_c) { FactoryBot.create(:contract_banded_fee_structure_band, banded_fee_structure:, min_declarations: 41, max_declarations: 100, fee_per_declaration: 100.0) }

  before do
    traits = %i[no_payment eligible payable paid voided awaiting_clawback clawed_back]
    traits.each do |trait|
      Declaration.declaration_types.each_key do |declaration_type|
        FactoryBot.create(:declaration, trait, declaration_type:)
      end
    end
  end

  describe "#declaration_type_outputs" do
    it "returns outputs for each valid declaration type" do
      expect(outputs.declaration_type_outputs.map(&:declaration_type).uniq).to match_array(declarations.map(&:declaration_type).uniq)
    end
  end

  describe "#total_billable_amount" do
    it "sums billable amounts across all declaration types" do
      # 27 billable declarations:
      # 3x started declarations (0.20 fee proportion)
      # 3x completed declarations (0.20 fee proportion)
      # 9x extended declarations (0.15 fee proportion)
      # 12x retained declarations (0.15 fee proportion)
      # 0.75 output fee ratio
      # 100.0 fee per declaration
      # fee proportion of ~0.1611111 (average across declaration types)
      expect(outputs.total_billable_amount).to eq((27 * 0.75 * 100.0 * 0.1611111).round(2))
    end
  end

  describe "#total_refundable_amount" do
    it "sums refundable amounts across all declaration types" do
      # 18 refundable declarations:
      # 2x started declarations (0.20 fee proportion)
      # 2x completed declarations (0.20 fee proportion)
      # 6x extended declarations (0.15 fee proportion)
      # 8x retained declarations (0.15 fee proportion)
      # 0.75 output fee ratio
      # 100.0 fee per declaration
      # fee proportion of ~0.1611111 (average across declaration types)
      expect(outputs.total_refundable_amount).to eq((18 * 0.75 * 100.0 * 0.1611111).round(2))
    end
  end

  describe "#total_net_amount" do
    it "returns total_billable_amount minus total_refundable_amount" do
      expect(outputs.total_net_amount).to eq(108.75)
    end
  end

  context "with no declarations" do
    before { Declaration.delete_all }

    it "returns zero for all amounts" do
      expect(outputs.total_billable_amount).to eq(0.0)
      expect(outputs.total_refundable_amount).to eq(0.0)
      expect(outputs.total_net_amount).to eq(0.0)
    end

    it "returns empty declaration type outputs" do
      expect(outputs.declaration_type_outputs).to be_empty
    end
  end
end
