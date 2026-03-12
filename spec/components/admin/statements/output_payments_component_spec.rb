RSpec.describe Admin::Statements::OutputPaymentsComponent, type: :component do
  subject(:component) { described_class.new(statement:) }

  let(:statement) { FactoryBot.create(:statement, contract:) }

  let(:banded_outputs) do
    bands = [
      { min_declarations: 1, max_declarations: 10 },
      { min_declarations: 11, max_declarations: 20 },
      { min_declarations: 21, max_declarations: 30 },
    ].map { FactoryBot.build_stubbed(:contract_banded_fee_structure_band, **it) }

    declaration_type_outputs = [
      double(
        declaration_type: "started",
        band: bands.first,
        billable_count: 10,
        type_adjusted_fee_per_declaration: 15,
        total_billable_amount: 150
      ),
      double(
        declaration_type: "started",
        band: bands.second,
        billable_count: 8,
        type_adjusted_fee_per_declaration: 12,
        total_billable_amount: 96
      ),
      double(
        declaration_type: "started",
        band: bands.third,
        billable_count: 5,
        type_adjusted_fee_per_declaration: 10,
        total_billable_amount: 50
      ),
      double(
        declaration_type: "completed",
        band: bands.first,
        billable_count: 3,
        type_adjusted_fee_per_declaration: 20,
        total_billable_amount: 60
      ),
      double(
        declaration_type: "completed",
        band: bands.second,
        billable_count: 0,
        type_adjusted_fee_per_declaration: 18,
        total_billable_amount: 0
      ),
      double(
        declaration_type: "completed",
        band: bands.third,
        billable_count: 0,
        type_adjusted_fee_per_declaration: 16,
        total_billable_amount: 0
      )
    ]

    instance_double(
      PaymentCalculator::Banded::Outputs,
      declaration_type_outputs:,
      total_billable_amount: 356
    )
  end

  let(:flat_rate_outputs) do
    declaration_type_outputs = [
      {
        declaration_type: "started",
        billable_count: 15,
        type_adjusted_fee_per_declaration: 500,
        total_billable_amount: 7500
      },
      {
        declaration_type: "completed",
        billable_count: 5,
        type_adjusted_fee_per_declaration: 500,
        total_billable_amount: 2500
      },
    ].map { instance_double(PaymentCalculator::FlatRate::DeclarationTypeOutput, **it) }

    instance_double(
      PaymentCalculator::FlatRate::Outputs,
      declaration_type_outputs:,
      total_billable_amount: 10_000
    )
  end

  before do
    allow(PaymentCalculator::Banded::Outputs).to receive(:new).and_return(banded_outputs)
    allow(PaymentCalculator::FlatRate::Outputs).to receive(:new).and_return(flat_rate_outputs)
    render_inline(component)
  end

  context "for `ecf` contracts" do
    let(:contract) { FactoryBot.create(:contract, :for_ecf) }

    it "renders one table of output payments" do
      expect(page).to have_css("table", count: 1)
    end

    it "renders declaration type count rows with billable counts and fees per band" do
      expect(page).to have_statement_table(
        caption: "Output payments",
        headings: ["Outputs", "Band A", "Band B", "Band C", "Payments"],
        rows: [
          ["Started", "10", "8", "5", ""],
          ["Fee per participant", "£15.00", "£12.00", "£10.00", "£296.00"],
          ["Completed", "3", "0", "0", ""],
          ["Fee per participant", "£20.00", "£18.00", "£16.00", "£60.00"]
        ],
        total_label: "Output payment total",
        total: "£356.00"
      )
    end
  end

  context "for `ittecf_ectp` contracts" do
    let(:contract) { FactoryBot.create(:contract, :for_ittecf_ectp) }

    it "renders the ECTs output payment table" do
      expect(page).to have_statement_table(
        caption: "Early career teacher (ECT) output payments",
        headings: ["Outputs", "Band A", "Band B", "Band C", "Payments"],
        rows: [
          ["Started", "10", "8", "5", ""],
          ["Fee per ECT", "£15.00", "£12.00", "£10.00", "£296.00"],
          ["Completed", "3", "0", "0", ""],
          ["Fee per ECT", "£20.00", "£18.00", "£16.00", "£60.00"],
        ],
        total_label: "ECTs output payment total",
        total: "£356.00"
      )
    end

    it "renders the Mentor output payment table" do
      expect(page).to have_statement_table(
        caption: "Mentor output payments",
        headings: %w[Outputs Participants Payments],
        rows: [
          ["Started", "15", ""],
          ["Fee per mentor", "£500.00", "£7,500.00"],
          ["Completed", "5", ""],
          ["Fee per mentor", "£500.00", "£2,500.00"],
        ],
        total_label: "Mentors output payment total",
        total: "£10,000.00"
      )
    end
  end

  context "for service fee statements" do
    let(:contract) { FactoryBot.create(:contract, :for_ecf) }
    let(:statement) { FactoryBot.create(:statement, contract:, fee_type: :service) }

    it "does not render" do
      expect(page).not_to have_css("table")
    end
  end
end
