RSpec.describe Admin::Statements::ProviderTargetsComponent::BandedFeeComponent, type: :component do
  subject(:component) { described_class.new(contract:) }

  let(:banded_fee_structure) do
    FactoryBot.build_stubbed(
      :contract_banded_fee_structure,
      :with_bands,
      recruitment_target: 2500,
      uplift_fee_per_declaration: 50,
      setup_fee: 5000,
      declaration_boundaries: [
        { min: 1, max: 50 },
        { min: 51, max: 100 },
        { min: 101, max: 150 }
      ]
    )
  end

  before { render_inline(component) }

  context "when there is no banded fee structure" do
    let(:contract) { FactoryBot.build_stubbed(:contract, banded_fee_structure: nil) }

    it "does not render anything" do
      expect(page).to have_no_selector("body")
    end
  end

  context "for `ecf` contracts" do
    let(:contract) do
      FactoryBot.build_stubbed(:contract, :for_ecf, banded_fee_structure:)
    end

    it "renders the recruitment target" do
      expect(page).to have_summary_list_row("Recruitment target", value: "2500")
    end

    it "renders the revised recruitment target" do
      expect(page).to have_summary_list_row("Revised recruitment target (150%)", value: "3750")
    end

    it "renders the uplift target" do
      expect(page).to have_summary_list_row("Uplift target", value: "33%")
    end

    it "renders the uplift amount" do
      expect(page).to have_summary_list_row("Uplift amount", value: "£50.00")
    end

    it "renders the setup fee" do
      expect(page).to have_summary_list_row("Setup fee", value: "£5,000.00")
    end

    it "renders a table of the bands" do
      expect(page).to have_statement_table(
        caption: "Contract bands",
        headings: ["Band", "Min", "Max", "Payment amount per participant"],
        rows: [
          ["Band A", 1, 50, /£\d+\.\d{2}/],
          ["Band B", 51, 100, /£\d+\.\d{2}/],
          ["Band C", 101, 150, /£\d+\.\d{2}/]
        ]
      )
    end
  end

  context "for `ittecf_ectp` contracts" do
    let(:contract) do
      FactoryBot.build_stubbed(:contract, :for_ittecf_ectp, banded_fee_structure:)
    end

    it "renders the recruitment target" do
      expect(page).to have_summary_list_row("ECTs recruitment target", value: "2500")
    end

    it "renders the revised recruitment target" do
      expect(page).to have_summary_list_row("Revised recruitment target (150%)", value: "3750")
    end

    it "does not render the uplift target" do
      expect(page).not_to have_summary_list_row("Uplift target")
    end

    it "does not render the uplift amount" do
      expect(page).not_to have_summary_list_row("Uplift amount")
    end

    it "renders the setup fee" do
      expect(page).to have_summary_list_row("Setup fee", value: "£5,000.00")
    end

    it "renders a table of the bands" do
      expect(page).to have_statement_table(
        caption: "Contract bands",
        headings: ["Band", "Min", "Max", "Payment amount per participant"],
        rows: [
          ["Band A", 1, 50, /£\d+\.\d{2}/],
          ["Band B", 51, 100, /£\d+\.\d{2}/],
          ["Band C", 101, 150, /£\d+\.\d{2}/]
        ]
      )
    end
  end
end
