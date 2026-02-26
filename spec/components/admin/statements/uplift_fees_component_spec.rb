RSpec.describe Admin::Statements::UpliftFeesComponent, type: :component do
  subject { render_inline(component) }

  let(:component) { described_class.new(statement:) }
  let(:contract) { FactoryBot.create(:contract, contract_type) }
  let(:statement) { FactoryBot.create(:statement, statement_type, contract:) }
  let(:fee_amount) { statement.contract.banded_fee_structure.uplift_fee_per_declaration }
  let(:school_partnership) { FactoryBot.create(:school_partnership, active_lead_provider: contract.active_lead_provider) }

  before do
    non_uplift_training_period = FactoryBot.create(:training_period, school_partnership:)
    FactoryBot.create(:declaration, declaration_type: "started", payment_statement: statement,
                                    payment_status: :payable, training_period: non_uplift_training_period)
  end

  shared_examples "does not render" do
    it "does not render" do
      expect(subject.text).to be_blank
    end
  end

  shared_examples "renders the table" do
    it { is_expected.to have_css("caption", text: "Uplift fees") }
    it { is_expected.to have_css("th:nth-child(1)", text: "Number of participants") }
    it { is_expected.to have_css("th:nth-child(2)", text: "Fee per participant") }
    it { is_expected.to have_css("th:nth-child(3)", text: "Payments") }
  end

  context "with an ECF (pre-2025) statement" do
    let(:contract_type) { :for_ecf }

    context "with service_fee" do
      let(:statement_type) { :service_fee }

      include_examples "does not render"
    end

    context "with output_fee" do
      let(:statement_type) { :output_fee }

      context "and no declarations with uplift fees" do
        include_examples "renders the table"

        it do
          is_expected.to have_table rows: [
            ["0", pounds(fee_amount), "£0.00"],
          ]
        end

        describe "total" do
          it { is_expected.to have_css(".govuk-heading-s", text: "Total") }
          it { is_expected.to have_css(".govuk-heading-s", text: "£0.00") }
        end
      end

      context "and declarations with uplift fees" do
        before do
          2.times do
            training_period = FactoryBot.create(:training_period, school_partnership:)
            FactoryBot.create(:declaration, declaration_type: "started", payment_statement: statement,
                                            payment_status: :payable, training_period:, pupil_premium_uplift: true)
          end
        end

        include_examples "renders the table"

        it do
          is_expected.to have_table rows: [
            ["2", pounds(fee_amount), pounds(2 * fee_amount)],
          ]
        end

        describe "total" do
          it { is_expected.to have_css(".govuk-heading-s", text: "Total") }
          it { is_expected.to have_css(".govuk-heading-s", text: pounds(2 * fee_amount)) }
        end
      end
    end
  end

  context "with an ITTECF ECTP (post-2025) statement" do
    let(:contract_type) { :for_ittecf_ectp }

    context "with service_fee" do
      let(:statement_type) { :service_fee }

      include_examples "does not render"
    end

    context "with output_fee" do
      let(:statement_type) { :output_fee }

      include_examples "does not render"
    end
  end

  def pounds(amount)
    ActionController::Base.helpers.number_to_currency(amount, precision: 2, unit: "£")
  end
end
