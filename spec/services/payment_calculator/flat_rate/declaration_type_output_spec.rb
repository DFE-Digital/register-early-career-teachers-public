RSpec.describe PaymentCalculator::FlatRate::DeclarationTypeOutput do
  subject(:output) do
    described_class.new(
      declarations: Declaration.all,
      declaration_type:,
      fee_per_declaration:,
      fee_proportions:
    )
  end

  let(:fee_per_declaration) { 100.0 }
  let(:declaration_type) { "started" }
  let(:fee_proportions) { { started: 0.5, completed: 0.5 } }

  before do
    traits = %i[no_payment eligible payable paid voided awaiting_clawback clawed_back]
    traits.each do |trait|
      # Create a `started` declaration for each trait
      FactoryBot.create(:declaration, trait, declaration_type:)
      # Create a `completed` declaration for each trait, should not be counted
      FactoryBot.create(:declaration, trait, declaration_type: "completed")
    end
  end

  describe "#billable_count" do
    it "counts declarations with billable statuses" do
      expect(output.billable_count).to eq(3)
    end
  end

  describe "#refundable_count" do
    it "counts declarations with refundable statuses" do
      expect(output.refundable_count).to eq(2)
    end
  end

  describe "#total_billable_amount" do
    it "returns billable_count multiplied by fee_per_declaration and fee proportion" do
      expect(output.total_billable_amount).to eq(3 * 100.0 * 0.5)
    end
  end

  describe "#total_refundable_amount" do
    it "returns refundable_count multiplied by fee_per_declaration and fee proportion" do
      expect(output.total_refundable_amount).to eq(2 * 100.0 * 0.5)
    end
  end

  describe "#total_net_amount" do
    it "returns total_billable_amount minus total_refundable_amount" do
      expect(output.total_net_amount).to eq(50.0)
    end
  end

  context "with a zero fee" do
    let(:fee_per_declaration) { 0.0 }

    it "returns zero for all amounts" do
      expect(output.total_billable_amount).to eq(0.0)
      expect(output.total_refundable_amount).to eq(0.0)
      expect(output.total_net_amount).to eq(0.0)
    end
  end
end
