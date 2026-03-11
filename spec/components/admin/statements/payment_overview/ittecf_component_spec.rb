RSpec.describe Admin::Statements::PaymentOverview::IttecfComponent, type: :component do
  let(:component) { described_class.new statement: }

  let(:contract_period) { FactoryBot.create(:contract_period, year: 2025) }
  let(:school_partnership) { FactoryBot.create(:school_partnership, :for_year, year: contract_period.year) }
  let(:active_lead_provider) { school_partnership.active_lead_provider }

  let(:deadline_date) { Date.new(2025, 9, 30) }
  let(:payment_date) { Date.new(2025, 10, 15) }

  let(:statement_rec) { FactoryBot.create(:statement, year: 2025, month: 9, deadline_date:, payment_date:, contract:) }
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
  let(:flat_rate_outputs_double) { double(total_net_amount: 200, total_refundable_amount: -300) }

  let(:total_net_amount) { 400 }
  let(:total_refundable_amount) { -150 }
  let(:total_manual_adjustments_amount) { 375 }
  let(:monthly_service_fee) { 1_000 }

  let(:contract) do
    FactoryBot.create(:contract, :for_ittecf_ectp, :with_bands, active_lead_provider:, vat_rate: 0.20, banded_fee_structure:, flat_rate_fee_structure:)
  end

  let(:flat_rate_fee_structure) do
    FactoryBot.create(
      :contract_flat_rate_fee_structure,
      fee_per_declaration: 100.00
    )
  end

  let!(:adjustment) { FactoryBot.create(:statement_adjustment, statement: statement_rec, amount: total_manual_adjustments_amount) }

  describe "calculations" do
    before do
      allow(PaymentCalculator::FlatRate::Outputs)
      .to receive(:new)
      .and_return(flat_rate_outputs_double)
      allow(PaymentCalculator::Banded::Outputs)
      .to receive(:new)
      .and_return(banded_outputs_double)

      render_inline(component)
    end

    it "does not show rows for ECF contracts" do
      expect(page).not_to have_text("Uplift fees")
      expect(page).not_to have_text("Output payment")
      expect(page).not_to have_text("Clawbacks")
    end

    it "displays the milestone cutoff and payment dates" do
      expect(page).to have_content("30 September 2025")
      expect(page).to have_content("15 October 2025")
    end

    it "has a total payment which is the sum of net total for banded and flatrate" do
      # ect_output(400) + mentors_output(200) + monthly_service_fee(1000) +
      # total_manual_adjustments_amount(375) + vat(395)
      # setup fee is no longer included

      expect(page).to have_css("h2.govuk-heading-l", text: "£2,370.00")
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
            ["ECTs output payment", "£400.00"],
            ["Mentors output payment", "£200.00"],
            ["Service fee", "£1,000.00"],
            ["ECTs clawbacks", "-£150.00"],
            ["Mentors clawbacks", "-£300.00"],
            ["Additional adjustments", "£375.00"],
            ["VAT", "£395.00"],
          ],
          total: :not_present
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

    it "raises an error when trying to access flat_rate calculator" do
      expect { component.send(:flat_rate) }.to raise_error(ArgumentError)
    end
  end

  context "when more than two calculators are returned" do
    let(:resolver) { instance_double(PaymentCalculator::Resolver, calculators: [flat_rate_calculator, banded_calculator, banded_calculator]) }
    let(:banded_calculator) { instance_double(PaymentCalculator::Banded) }
    let(:flat_rate_calculator) { instance_double(PaymentCalculator::FlatRate) }

    before do
      allow(PaymentCalculator::Resolver)
        .to receive(:new)
        .and_return(resolver)
    end

    it "raises an error when trying to access flat_rate calculator" do
      expect { component.send(:flat_rate) }.to raise_error(ArgumentError, "Expected exactly 2 calculators for ECF contract type")
    end
  end

  context "when no flatrate calculators are returned" do
    let(:resolver) { instance_double(PaymentCalculator::Resolver, calculators: [banded_calculator, banded_calculator]) }
    let(:banded_calculator) { instance_double(PaymentCalculator::Banded) }

    before do
      allow(PaymentCalculator::Resolver)
        .to receive(:new)
        .and_return(resolver)
    end

    it "raises an error when trying to access flat_rate calculator" do
      expect { component.send(:flat_rate) }.to raise_error(ArgumentError, "Expected flat rate calculator for IITECF ECTP contract type")
    end
  end
end
