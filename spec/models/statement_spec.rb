describe Statement do
  describe "associations" do
    it { is_expected.to belong_to(:active_lead_provider) }
    it { is_expected.to have_many(:adjustments) }
    it { is_expected.to have_one(:lead_provider).through(:active_lead_provider) }
    it { is_expected.to have_one(:registration_period).through(:active_lead_provider) }
  end

  describe "validations" do
    subject { FactoryBot.create(:statement) }

    it { is_expected.to allow_values(true, false).for(:output_fee).with_message("Output fee must be true or false") }
    it { is_expected.not_to allow_value(nil).for(:output_fee).with_message("Output fee must be true or false") }
    it { is_expected.to validate_numericality_of(:month).only_integer.is_greater_than_or_equal_to(1).is_less_than_or_equal_to(12).with_message("Month must be a number between 1 and 12") }
    it { is_expected.to validate_numericality_of(:year).only_integer.is_greater_than_or_equal_to(2020).with_message("Year must be on or after 2020 and on or before #{described_class.maximum_year}") }
    it { is_expected.to validate_uniqueness_of(:active_lead_provider_id).scoped_to(:year, :month).with_message("Statement with the same month and year already exists for the lead provider") }
    it { is_expected.to validate_uniqueness_of(:api_id).case_insensitive.with_message("API id already exists for another statement") }
  end

  describe "scopes" do
    describe ".with_state" do
      let!(:statement1) { FactoryBot.create(:statement, :open) }
      let!(:statement2) { FactoryBot.create(:statement, :payable) }
      let!(:statement3) { FactoryBot.create(:statement, :paid) }

      it "selects only statements with states matching the provided name" do
        expect(described_class.with_state("open")).to contain_exactly(statement1)
      end

      it "selects only multiple statements with states matching the provided names" do
        expect(described_class.with_state("payable", "paid")).to contain_exactly(statement2, statement3)
      end
    end

    describe ".with_output_fee" do
      let!(:statement1) { FactoryBot.create(:statement, output_fee: true) }
      let!(:statement2) { FactoryBot.create(:statement, output_fee: false) }

      it "selects only output fee statements" do
        expect(described_class.with_output_fee).to contain_exactly(statement1)
      end
    end
  end

  describe ".maximum_year" do
    subject { described_class.maximum_year }

    it { is_expected.to eq(Date.current.year + 5) }
  end

  describe "state transitions" do
    context "when transitioning from open to payable" do
      let(:statement) { FactoryBot.create(:statement, :open) }

      it { expect { statement.mark_as_payable! }.to change(statement, :state).from("open").to("payable") }
    end

    context "when transitioning from payable to paid" do
      let(:statement) { FactoryBot.create(:statement, :payable) }

      it { expect { statement.mark_as_paid! }.to change(statement, :state).from("payable").to("paid") }
    end

    context "when transitioning to an invalid state" do
      let(:statement) { FactoryBot.create(:statement, :paid) }

      it { expect { statement.mark_as_payable! }.to raise_error(StateMachines::InvalidTransition) }
    end
  end

  describe "#shorthand_state" do
    subject(:shorthand_state) { statement.shorthand_state }

    let(:statement) { FactoryBot.build(:statement, state:) }

    context "when state is open" do
      let(:state) { :open }

      it { is_expected.to eq("OP") }
    end

    context "when state is payable" do
      let(:state) { :payable }

      it { is_expected.to eq("PB") }
    end

    context "when state is paid" do
      let(:state) { :paid }

      it { is_expected.to eq("PD") }
    end

    context "when state is unknown" do
      let(:state) { :unknown_state }

      it { expect { shorthand_state }.to raise_error(ArgumentError, "Unknown state: unknown_state") }
    end
  end

  context ".adjustment_editable?" do
    context "paid statement" do
      subject { FactoryBot.build(:statement, :paid) }

      it "returns false" do
        subject.output_fee = true
        expect(subject.adjustment_editable?).to be(false)

        subject.output_fee = false
        expect(subject.adjustment_editable?).to be(false)
      end
    end

    context "non-paid statement" do
      context "output_fee is true" do
        subject { FactoryBot.build(:statement, :open, output_fee: true) }

        it "returns true" do
          expect(subject.adjustment_editable?).to be(true)
        end
      end

      context "output_fee is false" do
        subject { FactoryBot.build(:statement, :open, output_fee: false) }

        it "returns false" do
          expect(subject.adjustment_editable?).to be(false)
        end
      end
    end
  end
end
