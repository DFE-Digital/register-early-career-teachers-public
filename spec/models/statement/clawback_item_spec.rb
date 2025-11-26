describe Statement::ClawbackItem do
  describe "associations" do
    it { is_expected.to belong_to(:statement) }
    it { is_expected.to belong_to(:declaration) }
  end

  describe "validations" do
    subject { FactoryBot.create(:statement_clawback_item) }

    it { is_expected.to be_valid }

    it { is_expected.to validate_presence_of(:statement_id).with_message("Statement must be specified") }
    it { is_expected.to validate_presence_of(:declaration_id).with_message("Declaration must be specified") }
    it { is_expected.to validate_uniqueness_of(:declaration_id).with_message("Declaration can only have one clawback item") }
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive.with_message("ECF ID must be unique").allow_nil }
    it { is_expected.to validate_inclusion_of(:status).in_array(described_class.statuses.keys).with_message("Choose a valid status") }

    context "when declaration does not have a payment item" do
      let(:declaration) { FactoryBot.create(:declaration) }
      let(:clawback_item) { FactoryBot.build(:statement_clawback_item, declaration:) }

      it "is not valid" do
        expect(clawback_item).not_to be_valid
        expect(clawback_item.errors[:declaration_id]).to include("Declaration must have a paid payment item before creating a clawback item")
      end
    end
  end

  describe "enums" do
    it "has a status enum" do
      expect(subject).to define_enum_for(:status)
        .with_values({
          awaiting_clawback: "awaiting_clawback",
          clawed_back: "clawed_back"
        })
        .validating(allowing_nil: false)
        .backed_by_column_of_type(:enum)
        .with_suffix
    end
  end

  describe "state transitions" do
    context "when transitioning from awaiting_clawback to clawed_back" do
      let(:clawback_item) { FactoryBot.create(:statement_clawback_item, status: :awaiting_clawback) }

      it { expect { clawback_item.mark_as_clawed_back! }.to change(clawback_item, :status).from("awaiting_clawback").to("clawed_back") }
    end

    context "when transitioning to an invalid state" do
      let(:clawback_item) { FactoryBot.create(:statement_clawback_item, status: :clawed_back) }

      it { expect { clawback_item.mark_as_clawed_back! }.to raise_error(StateMachines::InvalidTransition) }
    end
  end
end
