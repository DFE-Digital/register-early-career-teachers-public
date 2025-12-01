describe Statement::LineItem do
  describe "associations" do
    it { is_expected.to belong_to(:statement) }
    it { is_expected.to belong_to(:declaration) }
  end

  describe "validations" do
    subject { FactoryBot.create(:statement_line_item) }

    it { is_expected.to be_valid }

    it { is_expected.to validate_presence_of(:statement_id).with_message("Statement must be specified") }
    it { is_expected.to validate_presence_of(:declaration_id).with_message("Declaration must be specified") }
    it { is_expected.to validate_uniqueness_of(:status).scoped_to(:declaration_id).ignoring_case_sensitivity.with_message("Status must be unique per declaration") }
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive.with_message("ECF ID must be unique").allow_nil }
    it { is_expected.to validate_inclusion_of(:status).in_array(described_class.statuses.keys).with_message("Choose a valid status") }

    it "only allows at most two line items per declaration" do
      declaration = FactoryBot.create(:declaration)
      FactoryBot.create(:statement_line_item, declaration:, status: :paid)
      FactoryBot.create(:statement_line_item, declaration:, status: :awaiting_clawback)

      third_line_item = FactoryBot.build(:statement_line_item, declaration:)

      expect(third_line_item).not_to be_valid
      expect(third_line_item.errors[:declaration_id]).to include("A declaration can have at most two statement line items")
    end

    it "only allows at most one billable line item per declaration" do
      declaration = FactoryBot.create(:declaration)
      FactoryBot.create(:statement_line_item, :billable, declaration:)

      second_billable_line_item = FactoryBot.build(:statement_line_item, :billable, declaration:)

      expect(second_billable_line_item).not_to be_valid
      expect(second_billable_line_item.errors[:declaration_id]).to include("A declaration can have at most one billable statement line item")
    end

    it "only allows at most one refundable line item per declaration" do
      declaration = FactoryBot.create(:declaration)
      FactoryBot.create(:statement_line_item, :billable, declaration:)
      FactoryBot.create(:statement_line_item, :refundable, declaration:)

      second_billable_line_item = FactoryBot.build(:statement_line_item, :refundable, declaration:)

      expect(second_billable_line_item).not_to be_valid
      expect(second_billable_line_item.errors[:declaration_id]).to include("A declaration can have at most one refundable statement line item")
    end

    it "only allows a refundable line item if a billable line item exists for the declaration" do
      declaration = FactoryBot.create(:declaration)
      refundable_without_billable = FactoryBot.build(:statement_line_item, :refundable, declaration:)

      expect(refundable_without_billable).not_to be_valid
      expect(refundable_without_billable.errors[:declaration_id]).to include("A refundable statement line item requires an associated billable statement line item")
    end
  end

  describe "enums" do
    it "has a status enum" do
      expect(subject).to define_enum_for(:status)
        .with_values({
          eligible: "eligible",
          payable: "payable",
          paid: "paid",
          voided: "voided",
          ineligible: "ineligible",
          awaiting_clawback: "awaiting_clawback",
          clawed_back: "clawed_back"
        })
        .validating(allowing_nil: false)
        .backed_by_column_of_type(:enum)
        .with_suffix
    end
  end

  describe "scopes" do
    let!(:eligible_line_item) { FactoryBot.create(:statement_line_item, status: :eligible) }
    let!(:payable_line_item) { FactoryBot.create(:statement_line_item, status: :payable) }
    let!(:paid_line_item1) { FactoryBot.create(:statement_line_item, status: :paid) }
    let!(:paid_line_item2) { FactoryBot.create(:statement_line_item, status: :paid) }
    let!(:voided_line_item) { FactoryBot.create(:statement_line_item, status: :voided) }
    let!(:ineligible_line_item) { FactoryBot.create(:statement_line_item, status: :ineligible) }
    let!(:awaiting_clawback_line_item) { FactoryBot.create(:statement_line_item, status: :awaiting_clawback, declaration: paid_line_item1.declaration) }
    let!(:clawed_back_line_item) { FactoryBot.create(:statement_line_item, status: :clawed_back, declaration: paid_line_item2.declaration) }

    describe "#billable_status" do
      subject { described_class.billable_status }

      it { is_expected.to contain_exactly(eligible_line_item, payable_line_item, paid_line_item1, paid_line_item2) }
    end

    describe "#refundable_status" do
      subject { described_class.refundable_status }

      it { is_expected.to contain_exactly(awaiting_clawback_line_item, clawed_back_line_item) }
    end
  end

  describe "billable/refundable status methods" do
    let!(:eligible_line_item) { FactoryBot.create(:statement_line_item, status: :eligible) }
    let!(:payable_line_item) { FactoryBot.create(:statement_line_item, status: :payable) }
    let!(:paid_line_item1) { FactoryBot.create(:statement_line_item, status: :paid) }
    let!(:paid_line_item2) { FactoryBot.create(:statement_line_item, status: :paid) }
    let!(:voided_line_item) { FactoryBot.create(:statement_line_item, status: :voided) }
    let!(:ineligible_line_item) { FactoryBot.create(:statement_line_item, status: :ineligible) }
    let!(:awaiting_clawback_line_item) { FactoryBot.create(:statement_line_item, status: :awaiting_clawback, declaration: paid_line_item1.declaration) }
    let!(:clawed_back_line_item) { FactoryBot.create(:statement_line_item, status: :clawed_back, declaration: paid_line_item2.declaration) }

    describe "#billable_status?" do
      it "returns true for billable statuses" do
        expect(eligible_line_item).to be_billable_status
        expect(payable_line_item).to be_billable_status
        expect(paid_line_item1).to be_billable_status
        expect(paid_line_item2).to be_billable_status
      end

      it "returns false for non-billable statuses" do
        expect(voided_line_item).not_to be_billable_status
        expect(ineligible_line_item).not_to be_billable_status
        expect(awaiting_clawback_line_item).not_to be_billable_status
        expect(clawed_back_line_item).not_to be_billable_status
      end
    end

    describe "#refundable_status?" do
      it "returns true for refundable statuses" do
        expect(awaiting_clawback_line_item).to be_refundable_status
        expect(clawed_back_line_item).to be_refundable_status
      end

      it "returns false for non-refundable statuses" do
        expect(eligible_line_item).not_to be_refundable_status
        expect(payable_line_item).not_to be_refundable_status
        expect(paid_line_item1).not_to be_refundable_status
        expect(paid_line_item2).not_to be_refundable_status
        expect(voided_line_item).not_to be_refundable_status
        expect(ineligible_line_item).not_to be_refundable_status
      end
    end
  end

  describe "state transitions" do
    context "when transitioning from eligible to payable" do
      let(:line_item) { FactoryBot.create(:statement_line_item, status: :eligible) }

      it { expect { line_item.mark_as_payable! }.to change(line_item, :status).from("eligible").to("payable") }
    end

    context "when transitioning from payable to paid" do
      let(:line_item) { FactoryBot.create(:statement_line_item, status: :payable) }

      it { expect { line_item.mark_as_paid! }.to change(line_item, :status).from("payable").to("paid") }
    end

    context "when transitioning from eligible to voided" do
      let(:line_item) { FactoryBot.create(:statement_line_item, status: :eligible) }

      it { expect { line_item.mark_as_voided! }.to change(line_item, :status).from("eligible").to("voided") }
    end

    context "when transitioning from ineligible to voided" do
      let(:line_item) { FactoryBot.create(:statement_line_item, status: :ineligible) }

      it { expect { line_item.mark_as_voided! }.to change(line_item, :status).from("ineligible").to("voided") }
    end

    context "when transitioning from payable to voided" do
      let(:line_item) { FactoryBot.create(:statement_line_item, status: :payable) }

      it { expect { line_item.mark_as_voided! }.to change(line_item, :status).from("payable").to("voided") }
    end

    context "when transitioning from paid to awaiting_clawback" do
      let(:line_item) { FactoryBot.create(:statement_line_item, status: :paid) }

      it { expect { line_item.mark_as_awaiting_clawback! }.to change(line_item, :status).from("paid").to("awaiting_clawback") }
    end

    context "when transitioning from awaiting_clawback to clawed_back" do
      let(:billable_line_item) { FactoryBot.create(:statement_line_item, :billable) }
      let(:line_item) { FactoryBot.create(:statement_line_item, status: :awaiting_clawback, declaration: billable_line_item.declaration) }

      it { expect { line_item.mark_as_clawed_back! }.to change(line_item, :status).from("awaiting_clawback").to("clawed_back") }
    end

    context "when transitioning from eligible to ineligible" do
      let(:line_item) { FactoryBot.create(:statement_line_item, status: :eligible) }

      it { expect { line_item.mark_as_ineligible! }.to change(line_item, :status).from("eligible").to("ineligible") }
    end

    context "when transitioning to an invalid state" do
      let(:line_item) { FactoryBot.create(:statement_line_item, status: :paid) }

      it { expect { line_item.mark_as_payable! }.to raise_error(StateMachines::InvalidTransition) }
    end
  end
end
