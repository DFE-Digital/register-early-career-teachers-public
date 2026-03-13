RSpec.describe PaymentCalculator::Banded do
  subject(:banded) do
    described_class.new(statement: statement_july, banded_fee_structure:, declaration_selector:)
  end

  let(:school_partnership) do
    FactoryBot.create(:school_partnership, :for_year, year: Date.current.year)
  end
  let(:active_lead_provider) { school_partnership.active_lead_provider }

  let(:contract) do
    FactoryBot.create(:contract, :for_ittecf_ectp, active_lead_provider:, vat_rate: 0.20, banded_fee_structure:)
  end

  # Previous statements
  let!(:statement_may) do
    deadline_date = Date.new(2025, 5, 1).prev_day
    payment_date = Date.new(2025, 5, 25)
    FactoryBot.create(
      :statement,
      :paid,
      contract:,
      deadline_date:,
      payment_date:,
      year: payment_date.year,
      month: payment_date.month
    )
  end
  let!(:statement_june) do
    deadline_date = Date.new(2025, 6, 1).prev_day
    payment_date = Date.new(2025, 6, 25)
    FactoryBot.create(
      :statement,
      :paid,
      contract:,
      deadline_date:,
      payment_date:,
      year: payment_date.year,
      month: payment_date.month
    )
  end
  # Current statement
  let!(:statement_july) do
    deadline_date = Date.new(2025, 7, 1).prev_day
    payment_date = Date.new(2025, 7, 25)
    FactoryBot.create(
      :statement,
      :open,
      contract:,
      deadline_date:,
      payment_date:,
      year: payment_date.year,
      month: payment_date.month
    )
  end

  let(:banded_fee_structure) do
    FactoryBot.create(
      :contract_banded_fee_structure,
      :with_bands,
      monthly_service_fee: 1_000,
      setup_fee: 500,
      uplift_fee_per_declaration: 50,
      recruitment_target: 100,
      declaration_boundaries: [{ min: 1, max: 200 }]
    )
  end

  let(:training_period) do
    FactoryBot.create(:training_period, :for_ect, school_partnership:)
  end
  let!(:billable_declaration) do
    FactoryBot.create(
      :declaration,
      :payable,
      declaration_type: :started,
      training_period:,
      payment_statement: statement_july
    )
  end
  let!(:refundable_declaration) do
    FactoryBot.create(
      :declaration,
      payment_status: :paid,
      clawback_status: :awaiting_clawback,
      declaration_type: :completed,
      training_period:,
      payment_statement: statement_may,
      clawback_statement: statement_july
    )
  end
  let!(:non_billable_declaration) do
    FactoryBot.create(
      :declaration,
      :no_payment,
      declaration_type: :completed,
      training_period:,
      payment_statement: statement_july
    )
  end

  let(:declaration_selector) { ->(declarations) { declarations } }

  describe "#outputs" do
    let(:previous_training_period) do
      FactoryBot.create(:training_period, :for_ect, school_partnership:)
    end

    let!(:previous_billable_declaration) do
      FactoryBot.create(
        :declaration,
        :payable,
        declaration_type: :started,
        training_period: previous_training_period,
        payment_statement: statement_june
      )
    end

    let!(:previous_refundable_declaration) do
      FactoryBot.create(
        :declaration,
        payment_status: :paid,
        clawback_status: :awaiting_clawback,
        declaration_type: :completed,
        training_period: previous_training_period,
        payment_statement: statement_may,
        clawback_statement: statement_june
      )
    end

    let!(:previous_non_billable_declaration) do
      FactoryBot.create(
        :declaration,
        :no_payment,
        declaration_type: "retained-1",
        training_period: previous_training_period,
        payment_statement: statement_june
      )
    end

    it "initializes with the current statement billable declarations" do
      expect(banded.outputs.billable_declarations).to contain_exactly(billable_declaration)
    end

    it "initializes with the current statement refundable declarations" do
      expect(banded.outputs.refundable_declarations).to contain_exactly(refundable_declaration)
    end

    it "initializes with previous billable declarations" do
      # previous_billable_declaration: payment_statement=statement_june, payment_status=payable
      # previous_refundable_declaration: payment_statement=statement_may, payment_status=paid
      # refundable_declaration: payment_statement=statement_may, payment_status=paid
      #   (also refundable on the current statement, but still counts as previously billed)
      expect(banded.outputs.previous_billable_declarations).to contain_exactly(previous_billable_declaration, previous_refundable_declaration, refundable_declaration)
    end

    it "initializes with previous refundable declarations" do
      expect(banded.outputs.previous_refundable_declarations).to contain_exactly(previous_refundable_declaration)
    end

    it "initializes with the banded fee structure" do
      expect(banded.outputs.banded_fee_structure).to eq(banded_fee_structure)
    end
  end

  describe "#uplifts" do
    it "initializes with the current statement billable declarations" do
      expect(banded.uplifts.billable_declarations).to contain_exactly(billable_declaration)
    end

    it "initializes with the current statement refundable declarations" do
      expect(banded.uplifts.refundable_declarations).to contain_exactly(refundable_declaration)
    end

    it "initializes with the uplift fee per declaration" do
      expect(banded.uplifts.uplift_fee_per_declaration).to eq(banded_fee_structure.uplift_fee_per_declaration)
    end
  end

  describe "#monthly_service_fee" do
    context "when banded_fee_structure has an explicit monthly_service_fee" do
      it "returns the explicit value" do
        expect(banded.monthly_service_fee).to eq(1_000)
      end
    end

    context "when banded_fee_structure monthly_service_fee is nil" do
      let(:banded_fee_structure) do
        FactoryBot.create(
          :contract_banded_fee_structure,
          monthly_service_fee: nil
        )
      end

      it "delegates to ServiceFees#monthly_amount" do
        allow(PaymentCalculator::ServiceFees)
          .to receive(:new)
          .with(banded_fee_structure:)
          .and_return(double(monthly_amount: 750))

        expect(banded.monthly_service_fee).to eq(750)
      end
    end
  end

  describe "#setup_fee" do
    it "delegates to banded_fee_structure" do
      expect(banded.setup_fee).to eq(500)
    end
  end

  describe "#total_manual_adjustments_amount" do
    context "with no adjustments" do
      it "returns 0" do
        expect(banded.total_manual_adjustments_amount).to eq(0)
      end
    end

    context "with adjustments" do
      before do
        FactoryBot.create(:statement_adjustment, statement: statement_july, amount: 150)
        FactoryBot.create(:statement_adjustment, statement: statement_july, amount: -50)
      end

      it "returns the sum of adjustment amounts" do
        expect(banded.total_manual_adjustments_amount).to eq(100)
      end
    end
  end

  describe "#total_amount" do
    let(:outputs_double) { double(total_net_amount: 200) }
    let(:uplifts_double) { double(total_net_amount: 50) }

    before do
      allow(PaymentCalculator::Banded::Outputs)
        .to receive(:new)
        .and_return(outputs_double)
      allow(PaymentCalculator::Banded::Uplifts)
        .to receive(:new)
        .and_return(uplifts_double)
    end

    context "when with_vat is false" do
      it "returns the subtotal" do
        # subtotal = outputs(200) + uplifts(50) + monthly_service_fee(1000) + adjustments(0)
        expect(banded.total_amount(with_vat: false)).to eq(1_250)
      end
    end

    context "when with_vat is true" do
      it "returns the subtotal plus VAT" do
        # subtotal = 1250, VAT = 1250 * 0.20 = 250
        expect(banded.total_amount(with_vat: true)).to eq(1_500)
      end
    end
  end

  describe "#vat_amount" do
    subject { banded.vat_amount }

    let(:outputs_double) { double(total_net_amount: 200) }
    let(:uplifts_double) { double(total_net_amount: 50) }

    before do
      allow(PaymentCalculator::Banded::Outputs)
        .to receive(:new)
        .and_return(outputs_double)
      allow(PaymentCalculator::Banded::Uplifts)
        .to receive(:new)
        .and_return(uplifts_double)
    end

    it { is_expected.to eq(250) }
  end

  describe "#voided_declarations_count" do
    context "with no voided declarations" do
      it "returns 0" do
        expect(banded.voided_declarations_count).to eq(0)
      end
    end

    context "with voided ECT declarations" do
      let!(:voided_declarations) do
        FactoryBot.create_list(
          :declaration,
          4,
          :voided,
          :with_ect,
          school_partnership:,
          payment_statement: statement_july
        )
      end

      it "returns the count of voided declarations matching the selector" do
        expect(banded.voided_declarations_count).to eq(4)
      end
    end

    context "with voided mentor declarations" do
      let!(:voided_declarations) do
        FactoryBot.create_list(
          :declaration,
          2,
          :voided,
          :with_mentor,
          school_partnership:,
          payment_statement: statement_july
        )
      end

      it "returns the count of voided declarations matching the selector" do
        expect(banded.voided_declarations_count).to eq(2)
      end
    end
  end
end
