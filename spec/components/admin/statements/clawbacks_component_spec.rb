RSpec.describe Admin::Statements::ClawbacksComponent, type: :component do
  subject(:component) { described_class.new(statement:) }

  let(:statement) { FactoryBot.create(:statement, contract:) }

  let(:banded_fee_structure) do
    FactoryBot.build_stubbed(
      :contract_banded_fee_structure,
      :with_bands,
      declaration_boundaries: [
        { min: 1, max: 10 },
        { min: 11, max: 20 },
      ]
    )
  end

  let(:banded_outputs) do
    bands = banded_fee_structure.bands
    banded_declaration_type_outputs = [
      double(
        declaration_type: "started",
        band: bands.first,
        refundable_count: 10,
        type_adjusted_fee_per_declaration: 15,
        total_refundable_amount: 150
      ),
      double(
        declaration_type: "started",
        band: bands.second,
        refundable_count: 10,
        type_adjusted_fee_per_declaration: 15,
        total_refundable_amount: 150
      ),
      double(
        declaration_type: "completed",
        band: bands.first,
        refundable_count: 5,
        type_adjusted_fee_per_declaration: 20,
        total_refundable_amount: 100
      ),
      double(
        declaration_type: "completed",
        band: bands.second,
        refundable_count: 0,
        type_adjusted_fee_per_declaration: 20,
        total_refundable_amount: 0
      )
    ]

    instance_double(
      PaymentCalculator::Banded::Outputs,
      declaration_type_outputs: banded_declaration_type_outputs,
      total_refundable_amount: 400
    )
  end

  let(:flat_rate_declaration_type_outputs) do
    [
      instance_double(
        PaymentCalculator::FlatRate::DeclarationTypeOutput,
        declaration_type: "started",
        refundable_count: 15,
        type_adjusted_fee_per_declaration: 10,
        total_refundable_amount: 150
      ),
      instance_double(
        PaymentCalculator::FlatRate::DeclarationTypeOutput,
        declaration_type: "completed",
        refundable_count: 5,
        type_adjusted_fee_per_declaration: 16,
        total_refundable_amount: 80
      ),
    ]
  end
  let(:flat_rate_outputs) do
    instance_double(
      PaymentCalculator::FlatRate::Outputs,
      declaration_type_outputs: flat_rate_declaration_type_outputs,
      total_refundable_amount: 230
    )
  end

  before do
    allow(PaymentCalculator::Banded::Outputs).to receive(:new).and_return(banded_outputs)
    allow(PaymentCalculator::FlatRate::Outputs).to receive(:new).and_return(flat_rate_outputs)
    render_inline(component)
  end

  context "for `ecf` contracts" do
    let(:contract) { FactoryBot.create(:contract, :for_ecf) }

    it "renders one table of clawbacks" do
      expect(page).to have_css("table", count: 1)
    end

    it "renders the clawbacks table" do
      expect(page).to have_statement_table(
        caption: "Clawbacks",
        headings: [
          "Payment type",
          "Number of participants",
          "Fee per participant",
          "Payments"
        ],
        rows: [
          ["Started (Band A)", "10", "-£15.00", "-£150.00"],
          ["Started (Band B)", "10", "-£15.00", "-£150.00"],
          ["Completed (Band A)", "5", "-£20.00", "-£100.00"]
        ],
        total: "-£400.00"
      )
    end
  end

  context "for `ittecf_ectp` contracts" do
    let(:contract) { FactoryBot.create(:contract, :for_ittecf_ectp) }

    it "renders two tables of clawbacks with ECT clawbacks first" do
      expect(page).to have_css("table", count: 2)
      tables = page.find_all("table")
      expect(tables.first).to have_css("caption", text: "ECT clawbacks")
      expect(tables.last).to have_css("caption", text: "Mentor clawbacks")
    end

    it "renders ECT clawbacks" do
      expect(page).to have_statement_table(
        caption: "ECT clawbacks",
        headings: [
          "Payment type",
          "Number of participants",
          "Fee per participant",
          "Payments"
        ],
        rows: [
          ["Started (Band A)", "10", "-£15.00", "-£150.00"],
          ["Started (Band B)", "10", "-£15.00", "-£150.00"],
          ["Completed (Band A)", "5", "-£20.00", "-£100.00"]
        ],
        total: "-£400.00"
      )
    end

    it "renders Mentor clawbacks" do
      expect(page).to have_statement_table(
        caption: "Mentor clawbacks",
        headings: [
          "Payment type",
          "Number of participants",
          "Fee per participant",
          "Payments"
        ],
        rows: [
          ["Started", "15", "-£10.00", "-£150.00"],
          ["Completed", "5", "-£16.00", "-£80.00"]
        ],
        total: "-£230.00"
      )
    end
  end

private

  def band(from:, to:)
    FactoryBot.build_stubbed(
      :contract_banded_fee_structure_band,
      min_declarations: from,
      max_declarations: to
    )
  end
end
