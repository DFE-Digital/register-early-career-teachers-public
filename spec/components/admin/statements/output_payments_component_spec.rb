RSpec.describe Admin::Statements::OutputPaymentsComponent, type: :component do
  subject(:component) { described_class.new(statement:) }

  let(:statement) { FactoryBot.create(:statement, contract:) }

  let(:banded_fee_structure) do
    fs = FactoryBot.create(:contract_banded_fee_structure)
    [
      { min: 1, max: 10, fee: 100 },
      { min: 11, max: 20, fee: 75 },
      { min: 21, max: 30, fee: 50 },
    ].each do |attrs|
      FactoryBot.create(
        :contract_banded_fee_structure_band,
        banded_fee_structure: fs,
        min_declarations: attrs[:min],
        max_declarations: attrs[:max],
        fee_per_declaration: attrs[:fee],
        output_fee_ratio: 0.8,
        service_fee_ratio: 0.2
      )
    end
    fs.reload
  end

  let(:bands) { banded_fee_structure.bands }

  let(:banded_outputs) do
    fee_proportions = PaymentCalculator::Banded::DeclarationTypeOutput::FEE_PROPORTIONS
    billable_counts = { "started" => [10, 8, 5], "completed" => [3, 0, 0] }

    declaration_type_outputs = Declaration.declaration_types.keys.flat_map do |declaration_type|
      bands.map.with_index do |band, i|
        count = billable_counts.dig(declaration_type, i) || 0
        fee = fee_proportions[declaration_type] * band.output_fee_ratio * band.fee_per_declaration

        double(
          declaration_type:,
          band:,
          billable_count: count,
          type_adjusted_fee_per_declaration: fee,
          total_billable_amount: count * fee
        )
      end
    end

    instance_double(
      PaymentCalculator::Banded::Outputs,
      declaration_type_outputs:,
      total_billable_amount: 344
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
    let(:contract) { FactoryBot.create(:contract, :for_ecf, banded_fee_structure:) }

    it "renders one table of output payments" do
      expect(page).to have_css("table", count: 1)
    end

    it "renders all declaration types in order including empty rows" do
      expect(page).to have_statement_table(
        caption: "Output payments",
        headings: ["Outputs", "Band A", "Band B", "Band C", "Payments"],
        rows: [
          ["Started", "10", "8", "5", ""],
          ["Fee per participant", "£16.00", "£12.00", "£8.00", "£296.00"],
          ["Retained 1", "0", "0", "0", ""],
          ["Fee per participant", "£12.00", "£9.00", "£6.00", "£0.00"],
          ["Retained 2", "0", "0", "0", ""],
          ["Fee per participant", "£12.00", "£9.00", "£6.00", "£0.00"],
          ["Retained 3", "0", "0", "0", ""],
          ["Fee per participant", "£12.00", "£9.00", "£6.00", "£0.00"],
          ["Retained 4", "0", "0", "0", ""],
          ["Fee per participant", "£12.00", "£9.00", "£6.00", "£0.00"],
          ["Completed", "3", "0", "0", ""],
          ["Fee per participant", "£16.00", "£12.00", "£8.00", "£48.00"],
          ["Extended", "0", "0", "0", ""],
          ["Fee per participant", "£12.00", "£9.00", "£6.00", "£0.00"],
        ],
        total_label: "Output payment total",
        total: "£344.00"
      )
    end
  end

  context "for `ittecf_ectp` contracts" do
    let(:contract) { FactoryBot.create(:contract, :for_ittecf_ectp, banded_fee_structure:) }

    it "renders the ECTs output payment table with all declaration types" do
      expect(page).to have_statement_table(
        caption: "Early career teacher (ECT) output payments",
        headings: ["Outputs", "Band A", "Band B", "Band C", "Payments"],
        rows: [
          ["Started", "10", "8", "5", ""],
          ["Fee per ECT", "£16.00", "£12.00", "£8.00", "£296.00"],
          ["Retained 1", "0", "0", "0", ""],
          ["Fee per ECT", "£12.00", "£9.00", "£6.00", "£0.00"],
          ["Retained 2", "0", "0", "0", ""],
          ["Fee per ECT", "£12.00", "£9.00", "£6.00", "£0.00"],
          ["Retained 3", "0", "0", "0", ""],
          ["Fee per ECT", "£12.00", "£9.00", "£6.00", "£0.00"],
          ["Retained 4", "0", "0", "0", ""],
          ["Fee per ECT", "£12.00", "£9.00", "£6.00", "£0.00"],
          ["Completed", "3", "0", "0", ""],
          ["Fee per ECT", "£16.00", "£12.00", "£8.00", "£48.00"],
          ["Extended", "0", "0", "0", ""],
          ["Fee per ECT", "£12.00", "£9.00", "£6.00", "£0.00"],
        ],
        total_label: "ECTs output payment total",
        total: "£344.00"
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
    let(:contract) { FactoryBot.create(:contract, :for_ecf, banded_fee_structure:) }
    let(:statement) { FactoryBot.create(:statement, contract:, fee_type: :service) }

    it "does not render" do
      expect(page).not_to have_css("table")
    end
  end
end
