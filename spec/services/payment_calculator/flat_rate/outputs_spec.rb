RSpec.describe PaymentCalculator::FlatRate::Outputs do
  subject(:outputs) do
    described_class.new(
      declarations: Declaration.all,
      fee_per_declaration:,
      fee_proportions: { started: 0.5, completed: 0.5 }
    )
  end

  let(:fee_per_declaration) { 100.0 }

  before do
    traits = %i[no_payment eligible payable paid voided awaiting_clawback clawed_back]
    traits.each do |trait|
      FactoryBot.create(:declaration, trait, declaration_type: "started")
      FactoryBot.create(:declaration, trait, declaration_type: "completed")
    end
  end

  describe "#declaration_type_outputs" do
    it "returns an output for each declaration type" do
      expect(outputs.declaration_type_outputs.map(&:declaration_type)).to eq(Declaration.declaration_types.keys)
      expect(outputs.declaration_type_outputs).to all(have_attributes(declarations: Declaration.all, fee_per_declaration:))
    end
  end

  describe "#total_billable_amount" do
    it "sums billable amounts across all declaration types" do
      # 2x declaration types, 3x payment statuses, 100.0 fee per declaration, 0.5 fee proportion for each declaration type
      expect(outputs.total_billable_amount).to eq(2 * 3 * 100.0 * 0.5)
    end
  end

  describe "#total_refundable_amount" do
    it "sums refundable amounts across all declaration types" do
      # 2x declaration types, 2x refund statuses, 100.0 fee per declaration, 0.5 fee proportion for each declaration type
      expect(outputs.total_refundable_amount).to eq(2 * 2 * 100.0 * 0.5)
    end
  end

  describe "#total_net_amount" do
    it "returns total_billable_amount minus total_refundable_amount" do
      # 1x started and 1x completed declarations, fee per declaration of 100.0 and fee proportion of 0.5
      expect(outputs.total_net_amount).to eq(100.0)
    end
  end

  context "with a zero fee" do
    let(:fee_per_declaration) { 0.0 }

    it "returns zero for all amounts" do
      expect(outputs.total_billable_amount).to eq(0.0)
      expect(outputs.total_refundable_amount).to eq(0.0)
      expect(outputs.total_net_amount).to eq(0.0)
    end
  end

  context "with no declarations" do
    before { Declaration.delete_all }

    it "returns zero for all amounts" do
      expect(outputs.total_billable_amount).to eq(0.0)
      expect(outputs.total_refundable_amount).to eq(0.0)
      expect(outputs.total_net_amount).to eq(0.0)
    end

    it "still returns declaration type outputs for each type" do
      expect(outputs.declaration_type_outputs.size).to eq(Declaration.declaration_types.keys.size)
    end
  end
end
