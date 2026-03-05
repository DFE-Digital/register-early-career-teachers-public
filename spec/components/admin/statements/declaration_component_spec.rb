RSpec.describe Admin::Statements::DeclarationComponent, type: :component do
  subject { render_inline(component) }

  let(:component) { described_class.new statement: }

  let(:contract_period) { FactoryBot.create(:contract_period, :current) }

  let(:statement) { FactoryBot.create(:statement, :payable, :output_fee, contract:) }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:, lead_provider:) }

  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
  let(:school_partnership) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:) }
  let(:school) { school_partnership.school }

  let(:started_flatrate) do
    instance_double(
      PaymentCalculator::FlatRate::DeclarationTypeOutput,
      declaration_type: "started",
      billable_count: 10,
      refundable_count: 2
    )
  end

  let(:started_banded) do
    instance_double(
      PaymentCalculator::Banded::DeclarationTypeOutput,
      declaration_type: "started",
      billable_count: 10,
      refundable_count: 2
    )
  end

  let(:retained_banded) do
    instance_double(
      PaymentCalculator::Banded::DeclarationTypeOutput,
      declaration_type: "retained",
      billable_count: 5,
      refundable_count: 0
    )
  end

  let(:extended_banded) do
    instance_double(
      PaymentCalculator::Banded::DeclarationTypeOutput,
      declaration_type: "extended",
      billable_count: 3,
      refundable_count: 0
    )
  end

  let(:completed_banded) do
    instance_double(
      PaymentCalculator::Banded::DeclarationTypeOutput,
      declaration_type: "completed",
      billable_count: 7,
      refundable_count: 1
    )
  end

  let(:completed_flatrate) do
    instance_double(
      PaymentCalculator::FlatRate::DeclarationTypeOutput,
      declaration_type: "completed",
      billable_count: 7,
      refundable_count: 1
    )
  end

  let(:resolver) { instance_double(PaymentCalculator::Resolver) }
  let(:banded_calculator) { instance_double(PaymentCalculator::Banded) }
  let(:flat_rate_calculator) { instance_double(PaymentCalculator::FlatRate) }
  let(:banded_outputs) { instance_double(PaymentCalculator::Banded::Outputs) }
  let(:flat_rate_outputs) { instance_double(PaymentCalculator::FlatRate::Outputs) }

  before do
    FactoryBot.create_list(:declaration, 3, :voided, :with_ect, school_partnership:, payment_statement: statement)

    allow(PaymentCalculator::Resolver)
    .to receive(:new)
    .with(statement:, contract:)
    .and_return(resolver)

    allow(banded_calculator).to receive(:outputs).and_return(banded_outputs)

    allow(banded_outputs)
    .to receive(:declaration_type_outputs)
    .and_return([started_banded, retained_banded, completed_banded, extended_banded])
  end

  context "for an ecf contract" do
    let(:contract) { FactoryBot.create(:contract, :for_ecf, active_lead_provider:, contract_period:) }

    before do
      allow(resolver).to receive(:calculators)
      .and_return([banded_calculator])
    end

    it "renders the declaration types and counts" do
      expect(subject).to have_table rows: [
        %w[Started 8],
        %w[Retained 5],
        %w[Completed 6],
        %w[Extended 3],
        %w[Voided 3],
      ]
    end
  end

  context "for an ittecf_ectp contract" do
    let(:contract) { FactoryBot.create(:contract, :for_ittecf_ectp, active_lead_provider:, contract_period:) }

    before do
      allow(resolver).to receive(:calculators)
      .and_return([flat_rate_calculator, banded_calculator])

      allow(flat_rate_calculator).to receive(:outputs).and_return(flat_rate_outputs)

      allow(flat_rate_outputs)
      .to receive(:declaration_type_outputs)
      .and_return([started_flatrate, completed_flatrate])
    end

    it "renders the declaration types and counts" do
      expect(subject).to have_table rows: [
        %w[Started 16],
        %w[Retained 5],
        %w[Completed 12],
        %w[Extended 3],
        %w[Voided 3],
      ]
    end
  end
end
