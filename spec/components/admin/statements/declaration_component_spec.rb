RSpec.describe Admin::Statements::DeclarationComponent, type: :component do
  include Rails.application.routes.url_helpers

  subject(:component) { described_class.new(statement:) }

  let(:framework_agreement) { FactoryBot.create(:framework_agreement) }
  let!(:contract_period) { framework_agreement.contract_period }
  let(:contract) { FactoryBot.create(:contract, contract_trait, framework_agreement:, contract_period:) }
  let(:contract_trait) { :for_ecf }
  let(:statement_trait) { :output_fee }
  let(:statement) { FactoryBot.create(:statement, :payable, statement_trait, framework_agreement:, contract:) }

  let(:ect_training_period) { FactoryBot.create(:training_period, :for_ect, :unfinished, :with_framework_agreement, framework_agreement:, ect_at_school_period: FactoryBot.create(:ect_at_school_period, :unfinished)) }
  let!(:ect_declaration) { FactoryBot.create(:declaration, :voided, training_period: ect_training_period, payment_statement: statement) }
  let(:mentor_training_period) { FactoryBot.create(:training_period, :for_mentor, :unfinished, :with_framework_agreement, framework_agreement:, mentor_at_school_period: FactoryBot.create(:mentor_at_school_period, :unfinished)) }
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

    render_inline(component)
  end

  context "when one calculator is returned (ECF contract)" do
    let(:contract_trait) { :for_ecf }

    it "renders the summary with a single Total column" do
      expect(page).to have_statement_table(
        caption: "Declarations summary",
        headings: ["", "Total"],
        rows: [
          %w[Started 10],
          %w[Retained 20],
          %w[Completed 7],
          %w[Extended 3],
          %w[Clawbacks 6],
          %w[Voided 2],
        ]
      )
    end
  end

  context "when several calculators are returned (ITTECF contract)" do
    let(:contract_trait) { :for_ittecf_ectp }

    it "renders the summary with ECTs and Mentors columns, banded first" do
      expect(page).to have_statement_table(
        caption: "Declarations summary",
        headings: ["", "ECTs", "Mentors"],
        rows: [
          ["Started", "10", "9"],
          ["Retained", "20", "-"],
          ["Completed", "7", "2"],
          ["Extended", "3", "-"],
          ["Clawbacks", "6", "4"],
          ["Voided", "1", "1"],
        ]
      )
    end
  end

  describe "download CSV link" do
    context "when the statement is for output fees" do
      let(:statement_trait) { :output_fee }

      it "shows the CSV download link for output fee statements" do
        expect(page).to have_link(
          "Download declarations (CSV)",
          href: declarations_export_admin_finance_statement_path(statement, format: :csv)
        )
        expect(page).to have_css(".govuk-\\!-display-none-print", text: "Download declarations (CSV)")
      end
    end

    context "when the statement is for service fees" do
      let(:statement_trait) { :service_fee }

      it "does not show the CSV download link" do
        expect(page).not_to have_link("Download declarations (CSV)")
      end
    end
  end
end
