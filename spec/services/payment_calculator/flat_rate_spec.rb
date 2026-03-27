RSpec.describe PaymentCalculator::FlatRate do
  subject(:flat_rate) do
    described_class.new(statement:, flat_rate_fee_structure:, declaration_selector:, fee_proportions:)
  end

  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:) }
  let(:lead_provider) { FactoryBot.create(:lead_provider, vat_registered:) }
  let(:vat_registered) { true }

  let(:mentor_training_period) do
    FactoryBot.create(
      :training_period,
      :for_mentor,
      :with_active_lead_provider,
      active_lead_provider:
    )
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
    FactoryBot.create(
      :training_period,
      :for_ect,
      :with_active_lead_provider,
      active_lead_provider:
    )
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
    FactoryBot.create(:contract, :for_ittecf_ectp, active_lead_provider:, vat_rate: 0.20)
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
    subject(:total_amount) { flat_rate.total_amount(with_vat:) }

    before do
      allow(PaymentCalculator::FlatRate::Outputs)
        .to receive(:new)
        .and_return(double(total_net_amount: 100))
    end

    context "when `with_vat` is false" do
      let(:with_vat) { false }

      it { is_expected.to eq(100) }
    end

    context "when the lead provider is VAT registered" do
      let(:vat_registered) { true }

      context "when `with_vat` is true" do
        let(:with_vat) { true }

        it { is_expected.to eq(120) }
      end
    end

    context "when the lead provider is not VAT registered" do
      let(:vat_registered) { false }

      context "when `with_vat` is true" do
        let(:with_vat) { true }

        it { is_expected.to eq(100) }
      end
    end
  end

  describe "#vat_amount" do
    subject(:vat_amount) { flat_rate.vat_amount }

    before do
      allow(PaymentCalculator::FlatRate::Outputs)
        .to receive(:new)
        .and_return(double(total_net_amount: 200))
    end

    context "when the lead provider is VAT registered" do
      let(:vat_registered) { true }

      it { is_expected.to eq(40) }
    end

    context "when the lead provider is not VAT registered" do
      let(:vat_registered) { false }

      it { is_expected.to eq(0) }
    end
  end

  describe "#outputs" do
    subject(:outputs) { flat_rate.outputs }

    it "calls the `FlatRate::Outputs` service with filtered declarations" do
      expect(PaymentCalculator::FlatRate::Outputs)
        .to receive(:new)
        .with(
          billable_declarations: contain_exactly(
            mentor_billable_declaration
          ),
          refundable_declarations: contain_exactly(
            mentor_refundable_declaration
          ),
          fee_per_declaration: flat_rate_fee_structure.fee_per_declaration,
          fee_proportions:
        )

      outputs
    end
  end

  describe "#voided_declarations_count" do
    subject(:voided_declarations_count) { flat_rate.voided_declarations_count }

    context "with no voided declarations" do
      it { is_expected.to eq(0) }
    end

    context "with voided mentor declarations" do
      let!(:voided_declarations) do
        FactoryBot.create_list(
          :declaration,
          4,
          :voided,
          training_period: mentor_training_period,
          payment_statement: statement
        )
      end

      it { is_expected.to eq(4) }
    end

    context "with voided ECT declarations" do
      let!(:voided_declarations) do
        FactoryBot.create_list(
          :declaration,
          2,
          :voided,
          training_period: ect_training_period,
          payment_statement: statement
        )
      end

      it { is_expected.to eq(0) }
    end
  end
end
