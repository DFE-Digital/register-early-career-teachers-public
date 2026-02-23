RSpec.describe PaymentCalculator::Banded::Outputs do
  subject(:outputs) do
    described_class.new(
      declarations:,
      previous_declarations:,
      banded_fee_structure:
    )
  end

  let(:previous_declarations) { Declaration.payment_status_eligible.limit(1) }
  let(:declarations) { Declaration.where.not(id: previous_declarations.pluck(:id)) }
  let(:banded_fee_structure) { FactoryBot.create(:contract_banded_fee_structure) }
  let!(:band_a) { FactoryBot.create(:contract_banded_fee_structure_band, banded_fee_structure:, min_declarations: 1, max_declarations: 2, fee_per_declaration: 100.0) }
  let!(:band_b) { FactoryBot.create(:contract_banded_fee_structure_band, banded_fee_structure:, min_declarations: 3, max_declarations: 4, fee_per_declaration: 100.0) }
  let!(:band_c) { FactoryBot.create(:contract_banded_fee_structure_band, banded_fee_structure:, min_declarations: 5, max_declarations: 6, fee_per_declaration: 100.0) }

  before do
    FactoryBot.create_list(:declaration, 5, :eligible)
    FactoryBot.create_list(:declaration, 2, :awaiting_clawback)
  end

  describe "#declaration_type_outputs" do
    it "returns outputs for each valid declaration type" do
      expect(outputs.declaration_type_outputs.map(&:declaration_type).uniq).to match_array(declarations.map(&:declaration_type).uniq)
    end
  end

  describe "#total_billable_amount" do
    it "sums billable amounts across all declaration types" do
      # 3x eligible/started declarations (0.20 fee proportion)
      # 0.75 output fee ratio
      # 100.0 fee per declaration
      expect(outputs.total_billable_amount).to eq(3 * 0.75 * 100.0 * 0.20)
    end
  end

  describe "#total_refundable_amount" do
    it "sums refundable amounts across all declaration types" do
      # 2x refundable/started declarations (0.20 fee proportion)
      # 0.75 output fee ratio
      # 100.0 fee per declaration
      expect(outputs.total_refundable_amount).to eq(2 * 0.75 * 100.0 * 0.20)
    end
  end

  describe "#total_net_amount" do
    it "returns total_billable_amount minus total_refundable_amount" do
      expect(outputs.total_net_amount).to eq(15.0)
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
