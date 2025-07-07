describe Statement do
  describe "associations" do
    it { is_expected.to belong_to(:active_lead_provider) }
    it { is_expected.to have_many(:adjustments) }
    it { is_expected.to have_one(:lead_provider).through(:active_lead_provider) }
    it { is_expected.to have_one(:contract_period).through(:active_lead_provider) }
  end

  describe "validations" do
    subject { create(:statement) }

    it { is_expected.to validate_presence_of(:fee_type).with_message("Enter a fee type") }
    it { is_expected.to allow_values('output', 'service').for(:fee_type).with_message("Fee type must be output or service") }
    it { is_expected.not_to allow_value(nil).for(:fee_type).with_message("Fee type must be output or service") }
    it { is_expected.to validate_numericality_of(:month).only_integer.is_greater_than_or_equal_to(1).is_less_than_or_equal_to(12).with_message("Month must be a number between 1 and 12") }
    it { is_expected.to validate_numericality_of(:year).only_integer.is_greater_than_or_equal_to(2020).with_message("Year must be on or after 2020 and on or before #{described_class.maximum_year}") }
    it { is_expected.to validate_uniqueness_of(:active_lead_provider_id).scoped_to(:year, :month).with_message("Statement with the same month and year already exists for the lead provider") }
    it { is_expected.to validate_uniqueness_of(:api_id).case_insensitive.with_message("API id already exists for another statement") }
  end

  describe "scopes" do
    describe ".with_status" do
      let!(:statement1) { create(:statement, :open) }
      let!(:statement2) { create(:statement, :payable) }
      let!(:statement3) { create(:statement, :paid) }

      it "selects only statements with statuses matching the provided name" do
        expect(described_class.with_status("open")).to contain_exactly(statement1)
      end

      it "selects only multiple statements with statuses matching the provided names" do
        expect(described_class.with_status("payable", "paid")).to contain_exactly(statement2, statement3)
      end
    end

    describe ".with_fee_type" do
      let!(:statement1) { create(:statement, :output_fee) }
      let!(:statement2) { create(:statement, :service_fee) }

      context "when searching with 'output'" do
        it 'selects only output fee statements' do
          expect(described_class.with_fee_type('output')).to contain_exactly(statement1)
        end
      end

      context "when searching with 'service'" do
        it 'selects only output fee statements' do
          expect(described_class.with_fee_type('service')).to contain_exactly(statement2)
        end
      end
    end

    describe ".with_statement_date" do
      let!(:statement1) { create(:statement, year: 2025, month: 5) }
      let!(:statement2) { create(:statement, year: 2024, month: 6) }

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

  describe "state transitions" do
    context "when transitioning from open to payable" do
      let(:statement) { create(:statement, :open) }

      it { expect { statement.mark_as_payable! }.to change(statement, :status).from("open").to("payable") }
    end

    context "when transitioning from payable to paid" do
      let(:statement) { create(:statement, :payable) }

      it { expect { statement.mark_as_paid! }.to change(statement, :status).from("payable").to("paid") }
    end

    context "when transitioning to an invalid state" do
      let(:statement) { create(:statement, :paid) }

      it { expect { statement.mark_as_payable! }.to raise_error(StateMachines::InvalidTransition) }
    end
  end

  describe "#shorthand_status" do
    subject(:shorthand_status) { statement.shorthand_status }

    let(:statement) { build(:statement, status:) }

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

  context ".adjustment_editable?" do
    context "paid statement" do
      subject { build(:statement, :paid) }

      it "returns false" do
        subject.fee_type = 'output'
        expect(subject.adjustment_editable?).to be(false)

        subject.fee_type = 'service'
        expect(subject.adjustment_editable?).to be(false)
      end
    end

    context "non-paid statement" do
      context "output fee" do
        subject { build(:statement, :open, fee_type: 'output') }

        it "returns true" do
          expect(subject.adjustment_editable?).to be(true)
        end
      end

      context "service fee" do
        subject { build(:statement, :open, fee_type: 'service') }

        it "returns false" do
          expect(subject.adjustment_editable?).to be(false)
        end
      end
    end
  end

  context ".can_authorise_payment?" do
    context "open statement" do
      subject { build(:statement, :open) }

      it { expect(subject.can_authorise_payment?).to be(false) }
    end

    context "paid statement" do
      subject { build(:statement, :paid) }

      it { expect(subject.can_authorise_payment?).to be(false) }
    end

    context "payable statement" do
      context "service_fee statement" do
        subject { build(:statement, :payable, :service_fee) }

        it { expect(subject.can_authorise_payment?).to be(false) }
      end

      context "output_fee statement" do
        context "with deadline_date in future" do
          subject { build(:statement, :payable, :output_fee, deadline_date: 3.days.from_now.to_date) }

          it { expect(subject.can_authorise_payment?).to be(false) }
        end

        context "with deadline_date in past" do
          let(:deadline_date) { 3.days.ago.to_date }

          context "marked as payable" do
            subject { build(:statement, :payable, :output_fee, deadline_date:, marked_as_paid_at: Time.zone.now) }

            it { expect(subject.can_authorise_payment?).to be(false) }
          end

          context "is not marked as payable" do
            subject { build(:statement, :payable, :output_fee, deadline_date:, marked_as_paid_at: nil) }

            it { expect(subject.can_authorise_payment?).to be(true) }
          end
        end
      end
    end
  end
end
