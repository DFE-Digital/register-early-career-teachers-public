RSpec.describe Admin::Statements::AdjustmentsComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:statement) { FactoryBot.create(:statement) }
  let(:component) { described_class.new statement: }

  context "no adjustments" do
    before do
      render_inline(component)
    end

    it "has an adjustments table with no rows" do
      expect(page).to have_statement_table(
        caption: "Additional adjustments",
        headings: [
          "Payment type",
          "",
          "Payments",
        ],
        rows: [],
        total: "£0.00"
      )
    end

    it "has a link to add adjustments" do
      expect(page).to have_link("Add")
    end

    it "does not have links to change or remove adjustments" do
      expect(page).not_to have_link("Change")
      expect(page).not_to have_link("Remove")
    end
  end

  context "with adjustments" do
    before do
      FactoryBot.create :statement_adjustment, statement:, payment_type: "Big", amount: 995.00
      FactoryBot.create :statement_adjustment, statement:, payment_type: "Minus", amount: -9.99
      FactoryBot.create :statement_adjustment, statement:, payment_type: "Small", amount: 4.99

      render_inline(component)
    end

    it "has an adjustments table" do
      expect(page).to have_statement_table(
        caption: "Additional adjustments",
        headings: [
          "Payment type",
          "",
          "Payments",
        ],
        rows: [
          ["Big",   "Change | Remove", "£995.00"],
          ["Minus", "Change | Remove", "-£9.99"],
          ["Small", "Change | Remove", "£4.99"]
        ],
        total: "£990.00"
      )
    end
  end

  describe ".adjustment_editable?" do
    let!(:adjustment) { FactoryBot.create :statement_adjustment, statement:, payment_type: "Big amount", amount: 999.99 }

    before do
      render_inline(component)
    end

    context "non-paid statement" do
      it "has a link to add adjustments" do
        expect(page).to have_link("Add")
      end

      it "has links to change or remove adjustments" do
        expect(page).to have_link("Change")
        expect(page).to have_link("Remove")
      end
    end

    context "paid statement" do
      let(:statement) { FactoryBot.create :statement, :paid }

      it "does not have a link to add adjustments" do
        expect(page).not_to have_link("Add")
      end

      it "does not have links to change or remove adjustments" do
        expect(page).not_to have_link("Change")
        expect(page).not_to have_link("Remove")
      end
    end

    context "service fee statement" do
      let(:statement) { FactoryBot.create :statement, :service_fee }

      it "does not have a link to add adjustments" do
        expect(page).not_to have_link("Add")
      end

      it "does not have links to change or remove adjustments" do
        expect(page).not_to have_link("Change")
        expect(page).not_to have_link("Remove")
      end
    end
  end
end
