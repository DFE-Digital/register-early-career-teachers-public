RSpec.describe Admin::Statements::PaymentOverview::ECFComponent, type: :component do
  let(:component) { described_class.new statement: }

  let(:contract_period) { FactoryBot.create(:contract_period, year: 2024) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, :for_year, year: 2024) }

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
    FactoryBot.create(:contract, :for_ecf, :with_bands, active_lead_provider:, vat_rate: 0.20, banded_fee_structure:)
  end

  describe "calculations" do
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

      expect(page).to have_css("h2.govuk-heading-l", text: "£2,190.00")
    end

    it "renders the overview table" do
      within(".finance-panel__summary__total-payment-breakdown") do
        expect(page).to have_statement_table(
          caption: "",
          headings: [
            "Payment type",
            "Payments"
          ],
          rows: [
            ["Output payment", "£400.00"],
            ["Service fee", "£1,000.00"],
            ["Uplift fees", "£50.00"],
            ["Clawbacks", "-£150.00"],
            ["Additional adjustments", "£375.00"],
            ["VAT", "£365.00"],
          ]
        )
      end
    end
  end

  context "when no calculators are returned" do
    let(:resolver) { instance_double(PaymentCalculator::Resolver, calculators: []) }

    before do
      allow(PaymentCalculator::Resolver)
        .to receive(:new)
        .and_return(resolver)
    end

    it "raises an error when trying to access uplifts" do
      expect { component.send(:uplifts) }.to raise_error(ArgumentError, "Expected exactly 1 calculator for ECF contract type")
    end
  end

  context "when more than one calculator is returned" do
    let(:resolver) { instance_double(PaymentCalculator::Resolver, calculators: [flat_rate_calculator, banded_calculator]) }
    let(:banded_calculator) { instance_double(PaymentCalculator::Banded) }
    let(:flat_rate_calculator) { instance_double(PaymentCalculator::FlatRate) }

    before do
      allow(PaymentCalculator::Resolver)
        .to receive(:new)
        .and_return(resolver)
    end

    it "raises an error when trying to access uplifts" do
      expect { component.send(:uplifts) }.to raise_error(ArgumentError, "Expected exactly 1 calculator for ECF contract type")
    end
  end

  context "when no banded calculators are returned" do
    let(:resolver) { instance_double(PaymentCalculator::Resolver, calculators: [flat_rate_calculator]) }
    let(:flat_rate_calculator) { instance_double(PaymentCalculator::FlatRate) }

    before do
      allow(PaymentCalculator::Resolver)
        .to receive(:new)
        .and_return(resolver)
    end

    it "raises an error when trying to access uplifts" do
      expect { component.send(:uplifts) }.to raise_error(ArgumentError, "Expected Banded calculator for ECF contract type")
    end
  end
end
