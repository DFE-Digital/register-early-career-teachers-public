RSpec.describe PaymentCalculator::Banded do
  subject(:banded) do
    described_class.new(statement:, banded_fee_structure:, declaration_selector:)
  end

  let(:school_partnership) do
    FactoryBot.create(:school_partnership, :for_year, year: Date.current.year)
  end
  let(:active_lead_provider) { school_partnership.active_lead_provider }

  let(:contract) do
    FactoryBot.create(:contract, :for_ittecf_ectp, active_lead_provider:, vat_rate: 0.20, banded_fee_structure:)
  end

  let(:statement) do
    FactoryBot.create(:statement, active_lead_provider:, contract:, year: 2025, month: 6, payment_date: Date.new(2025, 7, 1))
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
      payment_statement: statement
    )
  end
  let!(:refundable_declaration) do
    FactoryBot.create(
      :declaration,
      :awaiting_clawback,
      declaration_type: :completed,
      training_period:,
      clawback_statement: statement
    )
  end
  let!(:non_billable_declaration) do
    FactoryBot.create(
      :declaration,
      :no_payment,
      declaration_type: :completed,
      training_period:,
      payment_statement: statement
    )
  end

  let(:declaration_selector) { ->(declarations) { declarations } }

  describe "#outputs" do
    let(:previous_statement) do
      FactoryBot.create(:statement, active_lead_provider:, contract:, year: 2025, month: 5, payment_date: Date.new(2025, 6, 1))
    end

    let(:previous_training_period) do
      FactoryBot.create(:training_period, :for_ect, school_partnership:)
    end

    let!(:previous_billable_declaration) do
      FactoryBot.create(
        :declaration,
        :payable,
        declaration_type: :started,
        training_period: previous_training_period,
        payment_statement: previous_statement
      )
    end

    let!(:previous_refundable_declaration) do
      FactoryBot.create(
        :declaration,
        :awaiting_clawback,
        declaration_type: :completed,
        training_period: previous_training_period,
        clawback_statement: previous_statement
      )
    end

    let!(:previous_non_billable_declaration) do
      FactoryBot.create(
        :declaration,
        :no_payment,
        declaration_type: "retained-1",
        training_period: previous_training_period,
        payment_statement: previous_statement
      )
    end

    it "initializes with the current statement declarations" do
      expect(banded.outputs.declarations).to contain_exactly(billable_declaration, refundable_declaration)
    end

    it "initializes with previous billable and refundable declarations" do
      expect(banded.outputs.previous_declarations).to contain_exactly(previous_billable_declaration, previous_refundable_declaration)
    end

    it "initializes with the banded fee structure" do
      expect(banded.outputs.banded_fee_structure).to eq(banded_fee_structure)
    end
  end

  describe "#uplifts" do
    it "initializes with the current statement declarations" do
      expect(banded.uplifts.declarations).to contain_exactly(billable_declaration, refundable_declaration)
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
          :with_bands,
          monthly_service_fee: nil,
          recruitment_target: 100,
          declaration_boundaries: [{ min: 1, max: 60 }, { min: 61, max: 120 }]
        )
      end

      it "fills bands in order up to recruitment target and divides by 29 payments" do
        band_a, band_b = banded_fee_structure.bands.order(:min_declarations)

        # recruitment_target = 100
        # Band A: capacity 60, fills 60, remaining = 40
        # Band B: capacity 60, fills 40, remaining = 0
        # total = (60 * band_a.fee * band_a.ratio) + (40 * band_b.fee * band_b.ratio)
        # monthly = total / 29
        expected = (
          (60 * band_a.fee_per_declaration * band_a.service_fee_ratio) +
          (40 * band_b.fee_per_declaration * band_b.service_fee_ratio)
        ) / 29

        expect(banded.monthly_service_fee).to eq(expected)
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
        FactoryBot.create(:statement_adjustment, statement:, amount: 150)
        FactoryBot.create(:statement_adjustment, statement:, amount: -50)
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
        # subtotal = outputs(200) + uplifts(50) + monthly_service_fee(1000) + setup_fee(500) + adjustments(0)
        expect(banded.total_amount(with_vat: false)).to eq(1_750)
      end
    end

    context "when with_vat is true" do
      it "returns the subtotal plus VAT" do
        # subtotal = 1750, VAT = 1750 * 0.20 = 350
        expect(banded.total_amount(with_vat: true)).to eq(2_100)
      end
    end
  end
end
