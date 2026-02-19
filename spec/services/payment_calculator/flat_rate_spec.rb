RSpec.describe PaymentCalculator::FlatRate do
  subject(:flat_rate) do
    described_class.new(statement:, flat_rate_fee_structure:, declaration_selector:, fee_proportions:)
  end

  let(:school_partnership) do
    FactoryBot.create(:school_partnership, :for_year, year: Date.current.year)
  end
  let(:active_lead_provider) { school_partnership.active_lead_provider }

  let(:mentor_training_period) do
    FactoryBot.create(:training_period, :for_mentor, school_partnership:)
  end
  let!(:mentor_billable_declaration) do
    FactoryBot.create(
      :declaration,
      :payable,
      declaration_type: :started,
      training_period: mentor_training_period,
      payment_statement: statement
    )
  end
  let!(:mentor_refundable_declaration) do
    FactoryBot.create(
      :declaration,
      :awaiting_clawback,
      declaration_type: :completed,
      training_period: mentor_training_period,
      clawback_statement: statement
    )
  end
  let!(:mentor_voidable_declaration) do
    FactoryBot.create(
      :declaration,
      :no_payment,
      declaration_type: :completed,
      training_period: mentor_training_period,
      payment_statement: statement
    )
  end
  let(:ect_training_period) do
    FactoryBot.create(:training_period, :for_ect, school_partnership:)
  end
  let!(:ect_declaration) do
    FactoryBot.create(
      :declaration,
      :eligible,
      training_period: ect_training_period,
      payment_statement: statement
    )
  end

  let(:statement) do
    FactoryBot.create(:statement, active_lead_provider:)
  end
  let(:contract) do
    FactoryBot.create(:contract, :for_ittecf_ectp, vat_rate: 0.20)
  end
  let(:flat_rate_fee_structure) do
    FactoryBot.create(
      :contract_flat_rate_fee_structure,
      contract:,
      fee_per_declaration: 100.00
    )
  end
  let(:declaration_selector) do
    ->(declarations) { declarations.select(&:for_mentor?) }
  end
  let(:fee_proportions) { { started: 0.5, completed: 0.5 } }

  describe "#total_amount" do
    subject { flat_rate.total_amount(with_vat:) }

    before do
      allow(PaymentCalculator::FlatRate::Outputs)
        .to receive(:new)
        .and_return(double(total_net_amount: 100))
    end

    context "when `with_vat` is false" do
      let(:with_vat) { false }

      it { is_expected.to eq(100) }
    end

    context "when `with_vat` is true" do
      let(:with_vat) { true }

      it { is_expected.to eq(120) }
    end
  end

  describe "#outputs" do
    it "calls the `FlatRate::Outputs` service with filtered declarations" do
      expect(PaymentCalculator::FlatRate::Outputs)
        .to receive(:new)
        .with(
          declarations: contain_exactly(
            mentor_billable_declaration,
            mentor_refundable_declaration
          ),
          fee_per_declaration: flat_rate_fee_structure.fee_per_declaration,
          fee_proportions:
        )

      flat_rate.outputs
    end
  end
end
