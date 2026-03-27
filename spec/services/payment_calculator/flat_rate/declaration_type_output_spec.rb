RSpec.describe PaymentCalculator::FlatRate::DeclarationTypeOutput do
  subject(:output) do
    described_class.new(
      billable_declarations:,
      refundable_declarations:,
      declaration_type:,
      fee_per_declaration:,
      fee_proportions:
    )
  end

  let(:fee_per_declaration) { 100.0 }
  let(:declaration_type) { "started" }
  let(:fee_proportions) { { started: 0.25, completed: 0.75 } }

  let(:billable_ids) { [] }
  let(:refundable_ids) { [] }
  let(:billable_declarations) { Declaration.where(id: billable_ids) }
  let(:refundable_declarations) { Declaration.where(id: refundable_ids) }

  before do
    %i[eligible payable paid].each do |trait|
      billable_ids << FactoryBot.create(:declaration, trait, declaration_type:).id
      billable_ids << FactoryBot.create(:declaration, trait, declaration_type: "completed").id
    end

    %i[awaiting_clawback clawed_back].each do |trait|
      refundable_ids << FactoryBot.create(:declaration, trait, declaration_type:).id
      refundable_ids << FactoryBot.create(:declaration, trait, declaration_type: "completed").id
    end

    %i[no_payment voided].each do |trait|
      FactoryBot.create(:declaration, trait, declaration_type:)
      FactoryBot.create(:declaration, trait, declaration_type: "completed")
    end
  end

  describe "#billable_count" do
    it "counts billable declarations of matching type" do
      # eligible(1) + payable(1) + paid(1) for "started"
      expect(output.billable_count).to eq(3)
    end
  end

  describe "#refundable_count" do
    it "counts refundable declarations of matching type" do
      # awaiting_clawback(1) + clawed_back(1) for "started"
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
