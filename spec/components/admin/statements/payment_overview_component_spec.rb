RSpec.describe Admin::Statements::PaymentOverviewComponent, type: :component do
  subject { render_inline(component) }

  let(:statement) { Admin::StatementPresenter.new(statement_rec) }
  let(:component) { described_class.new statement: }

  context "pre 2025" do
    let!(:contract_period) { FactoryBot.create(:contract_period, year: 2025) }

    let(:school_partnership) do
      FactoryBot.create(:school_partnership, :for_year, year: Date.current.year)
    end

    let(:active_lead_provider) { school_partnership.active_lead_provider }

    let(:statement_rec) { FactoryBot.create(:statement, year: 2025, month: 9, deadline_date:, payment_date:, contract:) }
    let(:deadline_date) { Date.new(2025, 9, 30) }
    let(:payment_date) { Date.new(2025, 10, 15) }

    let(:contract) do
      FactoryBot.create(:contract, :for_ittecf_ectp, active_lead_provider:, vat_rate: 0.20, banded_fee_structure:)
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

    let(:declaration_selector) { ->(declarations) { declarations } }

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

    it "displays the milestone cutoff and payment dates" do
      expect(subject).to have_content("30 September 2025")
      expect(subject).to have_content("15 October 2025")
    end

    it "has a total payment" do
      expect(subject).to have_selector(".govuk-table__caption--m", text: "£2,100.00")
    end

    it "has an output payment row" do
      expect(subject).to have_selector(".govuk-table__cell", text: "Output payment")
      expect(subject).to have_selector(".govuk-table__cell--numeric", text: "£200.00")
    end

    it "has a service fee row" do
      expect(subject).to have_selector(".govuk-table__cell", text: "Service fee")
      expect(subject).to have_selector(".govuk-table__cell--numeric", text: "£1,000.00")
    end

    it "has an uplift fee row" do
      expect(subject).to have_selector(".govuk-table__cell", text: "Uplift fees")
      expect(subject).to have_selector(".govuk-table__cell--numeric", text: "£50.00")
    end

    it "has a clawbacks row" do
      expect(subject).to have_selector(".govuk-table__cell", text: "Clawbacks")
      expect(subject).to have_selector(".govuk-table__cell--numeric", text: "£0.00")
    end

    it "has an additional adjustments row" do
      expect(subject).to have_selector(".govuk-table__cell", text: "Additional adjustments")
      expect(subject).to have_selector(".govuk-table__cell--numeric", text: "£0.00")
    end

    it "has a VAT row" do
      expect(subject).to have_selector(".govuk-table__cell", text: "VAT")
      expect(subject).to have_selector(".govuk-table__cell--numeric", text: "£200.00")
    end
  end
end
