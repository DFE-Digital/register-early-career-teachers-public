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

  describe "#billable?" do
    let(:all_states) { described_class.state_machines[:status].states.to_a.map(&:value) }

    it "returns true for billable statuses" do
      described_class::BILLABLE_STATUS.each do |status|
        line_item = FactoryBot.build(:statement_line_item, status:)
        expect(line_item).to be_billable
      end
    end

    it "returns false for non-billable statuses" do
      (all_states - described_class::BILLABLE_STATUS).each do |status|
        line_item = FactoryBot.build(:statement_line_item, status:)
        expect(line_item).not_to be_billable
      end
    end
  end

  describe "#refundable?" do
    let(:all_states) { described_class.state_machines[:status].states.to_a.map(&:value) }

    it "returns true for refundable statuses" do
      described_class::REFUNDABLE_STATUS.each do |status|
        line_item = FactoryBot.build(:statement_line_item, status:)
        expect(line_item).to be_refundable
      end
    end

    it "returns false for non-refundable statuses" do
      (all_states - described_class::REFUNDABLE_STATUS).each do |status|
        line_item = FactoryBot.build(:statement_line_item, status:)
        expect(line_item).not_to be_refundable
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
      let(:line_item) { FactoryBot.create(:statement_line_item, status: :awaiting_clawback) }

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
