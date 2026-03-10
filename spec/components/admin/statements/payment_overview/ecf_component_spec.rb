RSpec.describe Admin::Statements::PaymentOverview::ECFComponent, type: :component do
  let(:component) { described_class.new statement: }

  let(:contract_period) { FactoryBot.create(:contract_period, year: 2024) }
  let(:school_partnership) { FactoryBot.create(:school_partnership, :for_year, year: contract_period.year) }
  let(:active_lead_provider) { school_partnership.active_lead_provider }

  let(:deadline_date) { Date.new(2024, 9, 30) }
  let(:payment_date) { Date.new(2024, 10, 15) }

  let(:statement_rec) { FactoryBot.create(:statement, year: 2024, month: 9, deadline_date:, payment_date:, contract:) }
  let(:statement) { Admin::StatementPresenter.new(statement_rec) }

  let(:banded_fee_structure) do
    FactoryBot.create(
      :contract_banded_fee_structure,
      :with_bands,
      monthly_service_fee:,
      uplift_fee_per_declaration: 50,
      recruitment_target: 100,
      declaration_boundaries: [{ min: 1, max: 200 }]
    )
  end

  let(:banded_outputs_double) { double(total_net_amount:, total_refundable_amount:) }
  let(:uplifts_double) { double(total_net_amount: total_uplifts_amount) }

  let(:total_net_amount) { 400 }
  let(:total_refundable_amount) { -150 }
  let(:total_manual_adjustments_amount) { 375 }
  let(:monthly_service_fee) { 1_000 }
  let(:total_uplifts_amount) { 50 }

  let(:contract) do
    FactoryBot.create(:contract, :for_ecf, active_lead_provider:, vat_rate: 0.20, banded_fee_structure:)
  end

  before do
    FactoryBot.create(:statement_adjustment, statement: statement_rec, amount: total_manual_adjustments_amount)

    allow(PaymentCalculator::Banded::Uplifts)
      .to receive(:new)
      .and_return(uplifts_double)
    allow(PaymentCalculator::Banded::Outputs)
      .to receive(:new)
      .and_return(banded_outputs_double)

    render_inline(component)
  end

  it "does not show rows for ITTECF contracts" do
    expect(page).not_to have_text("ECTs output payment")
    expect(page).not_to have_text("Mentors output payment")
    expect(page).not_to have_text("ECTs clawbacks")
    expect(page).not_to have_text("Mentors clawbacks")
  end

  it "displays the milestone cutoff and payment dates" do
    expect(page).to have_content("30 September 2024")
    expect(page).to have_content("15 October 2024")
  end

  it "has a total payment which comes from the Banded calculator" do
    # total_net_amount(400) + uplifts_amount(50) + monthly_service_fee(1000) +
    # + total_manual_adjustments_amount(375) + vat(365)
    # NB setup fee is no longer included

    expect(page).to have_css(".govuk-table__caption--m", text: "£2,190.00")
  end

  it "sum the figures into the correct rows" do
    expect(page).to have_table with_rows: [
      ["Output payment", "£400.00"],
      ["Service fee", "£1,000.00"],
      ["Uplift fees", "£50.00"],
      ["Clawbacks", "-£150.00"],
      ["Additional adjustments", "£375.00"],
      ["VAT", "£365.00"],
    ]
  end
end
