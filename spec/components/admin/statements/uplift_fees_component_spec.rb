RSpec.describe Admin::Statements::UpliftFeesComponent, type: :component do
  subject(:component) { described_class.new(statement:) }

  let(:contract) { FactoryBot.create(:contract, contract_type) }
  let(:statement) { FactoryBot.create(:statement, statement_type, contract:) }

  let(:net_count) { 0 }
  let(:uplift_fee_per_declaration) { 100 }
  let(:total_net_amount) { net_count * uplift_fee_per_declaration }

  let(:uplifts) do
    instance_double(
      PaymentCalculator::Banded::Uplifts,
      net_count:,
      uplift_fee_per_declaration:,
      total_net_amount:
    )
  end

  before do
    resolver = instance_double(PaymentCalculator::Resolver)
    banded = instance_double(PaymentCalculator::Banded)

    allow(PaymentCalculator::Resolver).to receive(:new).and_return(resolver)
    allow(resolver).to receive(:calculators).and_return([banded])
    allow(banded).to receive(:is_a?).with(PaymentCalculator::Banded).and_return(true)
    allow(banded).to receive(:uplifts).and_return(uplifts)

    render_inline(component)
  end

  shared_examples "does not render" do
    it "does not render" do
      expect(page.text).to be_blank
    end
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
        it do
          expect(page).to have_statement_table(
            caption: "Uplift fees",
            headings: ["Number of participants", "Fee per participant", "Payments"],
            rows: [["0", "£100.00", "£0.00"]],
            total: "£0.00"
          )
        end
      end

      context "and declarations with uplift fees" do
        let(:net_count) { 2 }

        it do
          expect(page).to have_statement_table(
            caption: "Uplift fees",
            headings: ["Number of participants", "Fee per participant", "Payments"],
            rows: [["2", "£100.00", "£200.00"]],
            total: "£200.00"
          )
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
end
