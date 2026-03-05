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

  let(:started_output) do
    instance_double(
      PaymentCalculator::FlatRate::DeclarationTypeOutput,
      declaration_type: "started",
      billable_count: 10,
      refundable_count: 2
    )
  end

  let(:retained_output) do
    instance_double(
      PaymentCalculator::FlatRate::DeclarationTypeOutput,
      declaration_type: "retained",
      billable_count: 5,
      refundable_count: 0
    )
  end

  let(:extended_output) do
    instance_double(
      PaymentCalculator::FlatRate::DeclarationTypeOutput,
      declaration_type: "extended",
      billable_count: 6,
      refundable_count: 2
    )
  end

  let(:completed_output) do
    instance_double(
      PaymentCalculator::FlatRate::DeclarationTypeOutput,
      declaration_type: "completed",
      billable_count: 7,
      refundable_count: 1
    )
  end

  before do
    FactoryBot.create_list(:declaration, 3, :voided, :with_ect, school_partnership:, payment_statement: statement)

    allow(component).to receive(:declaration_type_outputs)
      .and_return([started_output, retained_output, completed_output, extended_output])
  end

  context "for an ittecf_ectp contract" do
    let(:contract) { FactoryBot.create(:contract, :for_ittecf_ectp, active_lead_provider:, contract_period:) }

    it "renders the declaration types and counts" do
      expect(subject).to have_table rows: [
        %w[Started 8],
        %w[Retained 5],
        %w[Completed 6],
        %w[Extended 4],
        %w[Voided 3],
      ]
    end
  end
end
