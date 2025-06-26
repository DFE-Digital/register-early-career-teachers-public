RSpec.describe Admin::Statements::AdjustmentsComponent, type: :component do
  subject { render_inline(component) }

  let(:statement) { FactoryBot.create(:statement) }
  let(:component) { described_class.new statement: }

  let(:summary_list_values) do
    subject.css(".govuk-summary-card .govuk-summary-list .govuk-summary-list__row").map do |row|
      row.css(".govuk-summary-list__key, .govuk-summary-list__value").map { |v| v.text.strip }
    end
  end

  context "no adjustments" do
    it "renders correctly" do
      expect(statement.adjustments.count).to eq(0)
      expect(summary_list_values.count).to eq(1)
      expect(summary_list_values[0][0]).to eq("No adjustments")

      expect(subject).to have_link("Add adjustment")
      expect(subject).not_to have_link("Change adjustment")
    end
  end

  context "one adjustment" do
    let!(:adjustment) { FactoryBot.create :statement_adjustment, statement:, payment_type: "Big amount", amount: 999.99 }

    it "renders correctly" do
      expect(statement.adjustments.count).to eq(1)
      expect(component.total_amount.to_s).to eq("999.99")

      expect(summary_list_values.count).to eq(2)

      expect(summary_list_values[0][0]).to eq("Big amount")
      expect(summary_list_values[0][1]).to eq("£999.99")

      expect(summary_list_values[1][0]).to eq("Total")
      expect(summary_list_values[1][1]).to eq("£999.99")

      expect(subject).to have_link("Add adjustment")
      expect(subject).to have_link("Change adjustment")
    end
  end

  context "multiple adjustments" do
    let!(:adjustment1) { FactoryBot.create :statement_adjustment, statement:, payment_type: "Big amount", amount: 999.99 }
    let!(:adjustment2) { FactoryBot.create :statement_adjustment, statement:, payment_type: "Negative amount", amount: -500.0 }
    let!(:adjustment3) { FactoryBot.create :statement_adjustment, statement:, payment_type: "Another amount", amount: 300.0 }

    it "renders correctly" do
      expect(statement.adjustments.count).to eq(3)
      expect(component.total_amount.to_s).to eq("799.99")

      expect(summary_list_values.count).to eq(4)

      expect(summary_list_values[0][0]).to eq("Big amount")
      expect(summary_list_values[0][1]).to eq("£999.99")

      expect(summary_list_values[1][0]).to eq("Negative amount")
      expect(summary_list_values[1][1]).to eq("-£500.00")

      expect(summary_list_values[2][0]).to eq("Another amount")
      expect(summary_list_values[2][1]).to eq("£300.00")

      expect(summary_list_values[3][0]).to eq("Total")
      expect(summary_list_values[3][1]).to eq("£799.99")

      expect(subject).to have_link("Add adjustment")
      expect(subject).to have_link("Change adjustment")
    end
  end

  context ".adjustment_editable?" do
    let!(:adjustment1) { FactoryBot.create :statement_adjustment, statement:, payment_type: "Big amount", amount: 999.99 }

    context "non-paid statement" do
      it "renders links" do
        expect(subject).to have_link("Add adjustment")
      end
    end

    context "paid statement" do
      let(:statement) { FactoryBot.create :statement, :paid }

      it "does not render links" do
        expect(subject).not_to have_link("Add adjustment")
      end
    end

    context "statement with output_fee=fase" do
      let(:statement) { FactoryBot.create :statement, output_fee: false }

      it "does not render links" do
        expect(subject).not_to have_link("Add adjustment")
      end
    end
  end
end
