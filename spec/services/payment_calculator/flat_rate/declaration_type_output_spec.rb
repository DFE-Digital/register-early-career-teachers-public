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
  let(:fee_proportions) { { started: 0.25, completed: 0.75 } }

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
      expect(output.total_billable_amount).to eq(3 * 100.0 * 0.25)
    end
  end

  describe "#total_refundable_amount" do
    it "returns refundable_count multiplied by fee_per_declaration and fee proportion" do
      expect(output.total_refundable_amount).to eq(2 * 100.0 * 0.25)
    end
  end

  describe "#total_net_amount" do
    it "returns total_billable_amount minus total_refundable_amount" do
      expect(output.total_net_amount).to eq(25.0)
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

  context "when a fee proportion is not set for a declaration type" do
    let(:fee_proportions) { { "completed": 0.5, "retained-1": 0.5 } }

    it "raises a DeclarationTypeNotSupportedError" do
      expect {
        output.total_net_amount
      }.to raise_error(described_class::DeclarationTypeNotSupportedError).with_message("No fee proportion defined for declaration type: #{declaration_type}")
    end
  end

  context "when fee proportions are inconsistent" do
    let(:fee_proportions) { { "started": 0.5, "completed": 0.6 } }

    it "raises a FeeProportionsInconsistencyError" do
      expect {
        output.total_net_amount
      }.to raise_error(described_class::FeeProportionsInconsistencyError).with_message("Fee proportions are inconsistent. Sum of proportions must be 1.")
    end
  end
end
