RSpec.describe Admin::Statements::DeclarationComponent, type: :component do
  subject { render_inline(component) }

  let(:component) { described_class.new statement: }

  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }
  let!(:contract_period) { active_lead_provider.contract_period }
  let(:contract) { FactoryBot.create(:contract, contract_trait, active_lead_provider:, contract_period:) }
  let(:contract_trait) { :for_ecf }
  let(:statement) { FactoryBot.create(:statement, :payable, :output_fee, active_lead_provider:, contract:) }

  let(:ect_training_period) { FactoryBot.create(:training_period, :for_ect, :ongoing, :with_active_lead_provider, active_lead_provider:) }
  let!(:ect_declaration) { FactoryBot.create(:declaration, :voided, training_period: ect_training_period, payment_statement: statement) }
  let(:mentor_training_period) { FactoryBot.create(:training_period, :for_mentor, :ongoing, :with_active_lead_provider, active_lead_provider:) }
  let!(:mentor_declaration) { FactoryBot.create(:declaration, :voided, training_period: mentor_training_period, payment_statement: statement) }

  let(:started_flatrate) do
    instance_double(
      PaymentCalculator::FlatRate::DeclarationTypeOutput,
      declaration_type: "started",
      billable_count: 9,
      refundable_count: 3
    )
  end

  let(:completed_flatrate) do
    instance_double(
      PaymentCalculator::FlatRate::DeclarationTypeOutput,
      declaration_type: "completed",
      billable_count: 2,
      refundable_count: 1
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

  let(:retained1_banded) do
    instance_double(
      PaymentCalculator::Banded::DeclarationTypeOutput,
      declaration_type: "retained-1",
      billable_count: 5,
      refundable_count: 0
    )
  end

  let(:retained2_banded) do
    instance_double(
      PaymentCalculator::Banded::DeclarationTypeOutput,
      declaration_type: "retained-2",
      billable_count: 15,
      refundable_count: 3
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

  let(:extended_banded) do
    instance_double(
      PaymentCalculator::Banded::DeclarationTypeOutput,
      declaration_type: "extended",
      billable_count: 3,
      refundable_count: 0
    )
  end

  let(:banded_outputs) do
    instance_double(
      PaymentCalculator::Banded::Outputs,
      declaration_type_outputs: [
        started_banded,
        retained1_banded,
        retained2_banded,
        completed_banded,
        extended_banded
      ],
      total_refundable_count: 6
    )
  end

  let(:flat_rate_outputs) do
    instance_double(
      PaymentCalculator::FlatRate::Outputs,
      declaration_type_outputs: [
        started_flatrate,
        completed_flatrate
      ],
      total_refundable_count: 4
    )
  end

  before do
    allow(PaymentCalculator::Banded::Outputs)
      .to receive(:new)
      .and_return(banded_outputs)

    allow(PaymentCalculator::FlatRate::Outputs)
      .to receive(:new)
      .and_return(flat_rate_outputs)
  end

  context "when no calculators are returned" do
    let(:contract) { FactoryBot.create(:contract, active_lead_provider:, contract_period:) }
    let(:resolver) { instance_double(PaymentCalculator::Resolver, calculators: []) }

    before do
      allow(PaymentCalculator::Resolver)
        .to receive(:new)
        .and_return(resolver)
    end

    it "raises an error" do
      expect { subject }.to raise_error(ArgumentError)
    end
  end

  context "when one calculator is returned (ECF contract)" do
    let(:contract_trait) { :for_ecf }

    it "renders the declaration types correctly" do
      expect(subject).to have_table rows: [
        ["Started", "10"],
        ["Retained", "20"],
        ["Completed", "7"],
        ["Extended", "3"],
        ["Clawed back", "6"],
        ["Voided", "2"],
      ]
    end

    it "shows the Total header" do
      expect(subject).to have_table(text: "Total")
    end
  end

  context "when several calculators are returned (ITTECF contract)" do
    let(:contract_trait) { :for_ittecf_ectp }

    it "displays banded first and flat rate second" do
      expect(subject).to have_table rows: [
        ["Started", "10", "9"],
        ["Retained", "20", "0"],
        ["Completed", "7", "2"],
        ["Extended", "3", "0"],
        ["Clawed back", "6", "4"],
        ["Voided", "1", "1"],
      ]
    end

    it "renders the correct headers" do
      expect(subject).to have_table(text: "ECTs")
      expect(subject).to have_table(text: "Mentors")
    end
  end
end
