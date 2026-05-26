describe Statement do
  describe "associations" do
    it { is_expected.to have_one(:active_lead_provider).through(:contract) }
    it { is_expected.to have_many(:adjustments) }
    it { is_expected.to have_many(:payment_declarations).class_name("Declaration").inverse_of(:payment_statement) }
    it { is_expected.to have_many(:clawback_declarations).class_name("Declaration").inverse_of(:clawback_statement) }
    it { is_expected.to have_one(:lead_provider).through(:active_lead_provider) }
    it { is_expected.to have_one(:contract_period).through(:active_lead_provider) }
    it { is_expected.to belong_to(:contract) }
  end

  describe "validations" do
    subject { FactoryBot.create(:statement) }

    it { is_expected.to validate_presence_of(:contract).with_message("Contract is required") }
    it { is_expected.to validate_presence_of(:fee_type).with_message("Enter a fee type") }
    it { is_expected.to validate_presence_of(:status).with_message("Enter a status") }
    it { is_expected.to allow_values(*described_class.fee_types.keys).for(:fee_type).with_message("Fee type must be output or service") }
    it { is_expected.not_to allow_value(nil).for(:fee_type).with_message("Fee type must be output or service") }
    it { is_expected.to validate_numericality_of(:month).only_integer.is_greater_than_or_equal_to(1).is_less_than_or_equal_to(12).with_message("Month must be a number between 1 and 12") }
    it { is_expected.to validate_numericality_of(:year).only_integer.is_greater_than_or_equal_to(2020).with_message("Year must be on or after 2020 and on or before #{described_class.maximum_year}") }
    it { is_expected.to validate_uniqueness_of(:api_id).case_insensitive.with_message("API id already exists for another statement") }
    it { is_expected.to allow_values(*described_class.statuses.keys).for(:status) }
    it { is_expected.not_to allow_value(nil).for(:status).with_message("Choose a valid status") }
    it { is_expected.to validate_inclusion_of(:fee_type).in_array(described_class.fee_types.keys).with_message("Fee type must be output or service") }
    it { is_expected.to validate_inclusion_of(:status).in_array(described_class.statuses.keys).with_message("Choose a valid status") }

    describe "uniqueness of month and year for the same active lead provider" do
      let(:active_lead_provider) { contract.active_lead_provider }
      let(:contract) { FactoryBot.create(:contract, :for_ittecf_ectp) }

      before { FactoryBot.create(:statement, active_lead_provider:, month: 5, year: 2024) }

      it "is not valid to create another statement with the same month and year for the same active lead provider" do
        statement = described_class.new(contract:, month: 5, year: 2024)
        expect(statement).not_to be_valid
        expect(statement.errors[:base]).to include("Statement with the same month and year already exists for this active lead provider")
      end

      it "is valid to create another statement with the same month and year for a different active lead provider" do
        other_active_lead_provider = FactoryBot.create(:active_lead_provider)
        other_contract = FactoryBot.create(:contract, :for_ittecf_ectp, active_lead_provider: other_active_lead_provider)
        statement = described_class.new(contract: other_contract, month: 5, year: 2024, deadline_date: Date.new(2024, 5, 1).prev_day)

        expect(statement).to be_valid
      end
    end

    describe "deadline date in the past validation" do
      subject { FactoryBot.build(:statement, deadline_date:) }

      context "when statement is `open` status" do
        let(:deadline_date) { 1.day.from_now.to_date }

        it { is_expected.to be_valid }
      end

      Statement.statuses.except(:open).each_key do |status|
        context "when statement is `#{status}` status" do
          subject { FactoryBot.build(:statement, status.to_sym, deadline_date:) }

          context "when `deadline_date` is in the future" do
            let(:deadline_date) { 1.day.from_now.to_date }

            it { is_expected.to have_one_error_only }
            it { is_expected.to have_error(:deadline_date, "Deadline date must be in the past") }
          end

          context "when `deadline_date` is in the past" do
            let(:deadline_date) { 1.day.ago.to_date }

            it { is_expected.to be_valid }
          end

          context "when `deadline_date` is today" do
            let(:deadline_date) { Date.current }

            it { is_expected.to have_one_error_only }
            it { is_expected.to have_error(:deadline_date, "Deadline date must be in the past") }
          end
        end
      end
    end
  end

  describe "declarative touch" do
    let(:instance) { FactoryBot.create(:statement) }
    let(:target) { instance }

    it_behaves_like "a declarative touch model", timestamp_attribute: :api_updated_at
  end

  describe "scopes" do
    describe ".with_status" do
      let!(:statement1) { FactoryBot.create(:statement, :open) }
      let!(:statement2) { FactoryBot.create(:statement, :payable) }
      let!(:statement3) { FactoryBot.create(:statement, :paid) }

      it "selects only statements with statuses matching the provided name" do
        expect(described_class.with_status("open")).to contain_exactly(statement1)
      end

      it "selects only multiple statements with statuses matching the provided names" do
        expect(described_class.with_status("payable", "paid")).to contain_exactly(statement2, statement3)
      end
    end

    describe ".with_fee_type" do
      let!(:statement1) { FactoryBot.create(:statement, :output_fee) }
      let!(:statement2) { FactoryBot.create(:statement, :service_fee) }

      context "when searching with 'output'" do
        it "selects only output fee statements" do
          expect(described_class.with_fee_type("output")).to contain_exactly(statement1)
        end
      end

      context "when searching with 'service'" do
        it "selects only output fee statements" do
          expect(described_class.with_fee_type("service")).to contain_exactly(statement2)
        end
      end
    end

    describe ".with_statement_date" do
      let!(:statement1) { FactoryBot.create(:statement, year: 2025, month: 5) }
      let!(:statement2) { FactoryBot.create(:statement, year: 2024, month: 6) }

      it "returns only matching statements" do
        expect(described_class.with_statement_date(year: 2024, month: 6)).to contain_exactly(statement2)
        expect(described_class.with_statement_date(year: 2025, month: 5)).to contain_exactly(statement1)
      end

      it "returns empty if none matching" do
        expect(described_class.with_statement_date(year: 2021, month: 1)).to be_empty
      end
    end
  end

  describe ".maximum_year" do
    subject { described_class.maximum_year }

    it { is_expected.to eq(Date.current.year + 5) }
  end

  describe "enums" do
    it "has a `status` enum" do
      expect(subject).to define_enum_for(:status)
        .with_values({
          open: "open",
          payable: "payable",
          paid: "paid",
        })
        .validating(allowing_nil: false)
        .backed_by_column_of_type(:enum)
        .with_prefix
    end

    it "has a `fee_type` enum" do
      expect(subject).to define_enum_for(:fee_type)
        .with_values({
          output: "output",
          service: "service"
        })
        .validating(allowing_nil: false)
        .with_suffix("fee")
        .backed_by_column_of_type(:enum)
    end
  end

  describe "state transitions" do
    context "when transitioning from open to payable" do
      let(:statement) { FactoryBot.create(:statement, :open) }

      it { expect { statement.mark_as_payable! }.to change(statement, :status).from("open").to("payable") }
    end

    context "when transitioning from payable to paid" do
      let(:statement) { FactoryBot.create(:statement, :payable) }

      it { expect { statement.mark_as_paid! }.to change(statement, :status).from("payable").to("paid") }
    end

    context "when transitioning to an invalid state" do
      let(:statement) { FactoryBot.create(:statement, :paid) }

      it { expect { statement.mark_as_payable! }.to raise_error(StateMachines::InvalidTransition) }
    end
  end

  describe "#shorthand_status" do
    subject(:shorthand_status) { statement.shorthand_status }

    let(:statement) { FactoryBot.build(:statement, status:) }

    context "when status is open" do
      let(:status) { :open }

      it { is_expected.to eq("OP") }
    end

    context "when status is payable" do
      let(:status) { :payable }

      it { is_expected.to eq("PB") }
    end

    context "when status is paid" do
      let(:status) { :paid }

      it { is_expected.to eq("PD") }
    end

    context "when status is unknown" do
      let(:status) { :unknown_status }

      it { expect { shorthand_status }.to raise_error(ArgumentError, "Unknown status: unknown_status") }
    end
  end

  describe ".adjustment_editable?" do
    context "paid statement" do
      subject { FactoryBot.build(:statement, :paid) }

      it "returns false" do
        subject.fee_type = "output"
        expect(subject.adjustment_editable?).to be(false)

        subject.fee_type = "service"
        expect(subject.adjustment_editable?).to be(false)
      end
    end

    context "non-paid statement" do
      context "output fee" do
        subject { FactoryBot.build(:statement, :open, fee_type: "output") }

        it "returns true" do
          expect(subject.adjustment_editable?).to be(true)
        end
      end

      context "service fee" do
        subject { FactoryBot.build(:statement, :open, fee_type: "service") }

        it "returns false" do
          expect(subject.adjustment_editable?).to be(false)
        end
      end
    end
  end

  describe ".can_authorise_payment?" do
    context "open statement" do
      subject { FactoryBot.build(:statement, :open) }

      it { expect(subject.can_authorise_payment?).to be(false) }
    end

    context "paid statement" do
      subject { FactoryBot.build(:statement, :paid) }

      it { expect(subject.can_authorise_payment?).to be(false) }
    end

    context "payable statement" do
      context "service_fee statement" do
        subject { FactoryBot.build(:statement, :payable, :service_fee) }

        it { expect(subject.can_authorise_payment?).to be(false) }
      end

      context "output_fee statement" do
        context "with deadline_date in future" do
          subject { FactoryBot.build(:statement, :payable, :output_fee, deadline_date: 3.days.from_now.to_date) }

          it { expect(subject.can_authorise_payment?).to be(false) }
        end

        context "with deadline_date in past" do
          let(:deadline_date) { 3.days.ago.to_date }

          context "marked as payable" do
            subject { FactoryBot.build(:statement, :payable, :output_fee, deadline_date:, marked_as_paid_at: Time.zone.now) }

            it { expect(subject.can_authorise_payment?).to be(false) }
          end

          context "is not marked as payable" do
            subject { FactoryBot.build(:statement, :payable, :output_fee, deadline_date:, marked_as_paid_at: nil) }

            it { expect(subject.can_authorise_payment?).to be(true) }
          end
        end
      end
    end
  end
end
