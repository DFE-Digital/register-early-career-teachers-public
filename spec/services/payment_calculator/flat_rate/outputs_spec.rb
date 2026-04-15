RSpec.describe PaymentCalculator::FlatRate::Outputs do
  subject(:outputs) do
    described_class.new(
      billable_declarations:,
      refundable_declarations:,
      fee_per_declaration:,
      fee_proportions:
    )
  end

  let(:fee_per_declaration) { 100.0 }
  let(:fee_proportions) { { started: 0.5, completed: 0.5 } }

  let(:billable_ids) { [] }
  let(:refundable_ids) { [] }
  let(:billable_declarations) { Declaration.where(id: billable_ids) }
  let(:refundable_declarations) { Declaration.where(id: refundable_ids) }

  before do
    %i[eligible payable paid].each do |trait|
      billable_ids << FactoryBot.create(:declaration, trait, declaration_type: "started").id
      billable_ids << FactoryBot.create(:declaration, trait, declaration_type: "completed").id
    end

    %i[awaiting_clawback clawed_back].each do |trait|
      refundable_ids << FactoryBot.create(:declaration, trait, declaration_type: "started").id
      refundable_ids << FactoryBot.create(:declaration, trait, declaration_type: "completed").id
    end

    %i[no_payment voided].each do |trait|
      FactoryBot.create(:declaration, trait, declaration_type: "started")
      FactoryBot.create(:declaration, trait, declaration_type: "completed")
    end
  end

  describe "#declaration_type_outputs" do
    it "returns an output for each valid declaration type" do
      expect(outputs.declaration_type_outputs.map(&:declaration_type)).to match_array(%w[started completed])
      expect(outputs.declaration_type_outputs).to all(have_attributes(
                                                        billable_declarations:,
                                                        refundable_declarations:,
                                                        fee_per_declaration:,
                                                        fee_proportions:
                                                      ))
    end
  end

  describe "#total_billable_amount" do
    it "sums billable amounts across all declaration types" do
      # 2x declaration types, 3x billable statuses (eligible, payable, paid),
      # 100.0 fee per declaration, 0.5 fee proportion for each declaration type
      expect(outputs.total_billable_amount).to eq(2 * 3 * 100.0 * 0.5)
    end
  end

  describe "#total_refundable_amount" do
    it "sums refundable amounts across all declaration types" do
      # 2x declaration types, 2x refund statuses, 100.0 fee per declaration, 0.5 fee proportion for each declaration type
      expect(outputs.total_refundable_amount).to eq(2 * 2 * 100.0 * 0.5)
    end
  end

  describe "#total_refundable_count" do
    it "sums refundable counts across all declaration types" do
      # 2x declaration types, 2x refund statuses
      expect(outputs.total_refundable_count).to eq(2 * 2)
    end
  end

  describe "#total_net_amount" do
    it "returns total_billable_amount minus total_refundable_amount" do
      # 2x declaration types (started, completed), 3x billable - 2x refundable, 100.0 fee per declaration and fee proportion of 0.5
      expect(outputs.total_net_amount).to eq((2 * 3 * 100.0 * 0.5) - (2 * 2 * 100.0 * 0.5))
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

    it "returns declaration type outputs with zero counts" do
      expect(outputs.declaration_type_outputs.map(&:declaration_type)).to match_array(%w[started completed])
      expect(outputs.declaration_type_outputs).to all(have_attributes(billable_count: 0, refundable_count: 0))
    end
  end
end
