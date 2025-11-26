describe Statement::PaymentItem do
  describe "associations" do
    it { is_expected.to belong_to(:statement) }
    it { is_expected.to belong_to(:declaration) }
  end

  describe "validations" do
    subject { FactoryBot.create(:statement_payment_item) }

    it { is_expected.to be_valid }

    it { is_expected.to validate_presence_of(:statement_id).with_message("Statement must be specified") }
    it { is_expected.to validate_presence_of(:declaration_id).with_message("Declaration must be specified") }
    it { is_expected.to validate_uniqueness_of(:declaration_id).with_message("Declaration can only have one payment item") }
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
        })
        .validating(allowing_nil: false)
        .backed_by_column_of_type(:enum)
        .with_suffix
    end
  end

  describe "state transitions" do
    context "when transitioning from eligible to payable" do
      let(:line_item) { FactoryBot.create(:statement_payment_item, status: :eligible) }

      it { expect { line_item.mark_as_payable! }.to change(line_item, :status).from("eligible").to("payable") }
    end

    context "when transitioning from payable to paid" do
      let(:line_item) { FactoryBot.create(:statement_payment_item, status: :payable) }

      it { expect { line_item.mark_as_paid! }.to change(line_item, :status).from("payable").to("paid") }
    end

    context "when transitioning from eligible to voided" do
      let(:line_item) { FactoryBot.create(:statement_payment_item, status: :eligible) }

      it { expect { line_item.mark_as_voided! }.to change(line_item, :status).from("eligible").to("voided") }
    end

    context "when transitioning from ineligible to voided" do
      let(:line_item) { FactoryBot.create(:statement_payment_item, status: :ineligible) }

      it { expect { line_item.mark_as_voided! }.to change(line_item, :status).from("ineligible").to("voided") }
    end

    context "when transitioning from payable to voided" do
      let(:line_item) { FactoryBot.create(:statement_payment_item, status: :payable) }

      it { expect { line_item.mark_as_voided! }.to change(line_item, :status).from("payable").to("voided") }
    end

    context "when transitioning from eligible to ineligible" do
      let(:line_item) { FactoryBot.create(:statement_payment_item, status: :eligible) }

      it { expect { line_item.mark_as_ineligible! }.to change(line_item, :status).from("eligible").to("ineligible") }
    end

    context "when transitioning to an invalid state" do
      let(:line_item) { FactoryBot.create(:statement_payment_item, status: :paid) }

      it { expect { line_item.mark_as_paid! }.to raise_error(StateMachines::InvalidTransition) }
    end
  end
end
