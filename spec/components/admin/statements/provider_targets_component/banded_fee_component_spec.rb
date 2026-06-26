RSpec.describe Admin::Statements::ProviderTargetsComponent::BandedFeeComponent, type: :component do
  subject(:component) { described_class.new(contract:) }

  let(:banded_fee_structure) do
    FactoryBot.build_stubbed(:contract_banded_fee_structure,
      recruitment_target: 2500,
      uplift_fee_per_declaration: 50,
      setup_fee: 5000)
  end

  let(:band_terms) do
    [[1, 50], [51, 100], [101, 150]].map do |min, max|
      FactoryBot.build_stubbed(:contract_banded_fee_structure_band_term,
        banded_fee_structure:,
        min_declarations: min,
        max_declarations: max,
        fee_per_declaration: 100,
        output_fee_ratio: 0.75,
        service_fee_ratio: 0.25)
    end
  end

  before { allow(banded_fee_structure).to receive(:band_terms).and_return(band_terms) }

  context "when there is no banded fee structure" do
    let(:contract) { FactoryBot.build_stubbed(:contract, banded_fee_structure: nil) }

    before { render_inline(component) }

    it "does not render anything" do
      expect(page).to have_no_selector("body")
    end
  end

  context "for `ecf` contracts" do
    let(:contract) { FactoryBot.build_stubbed(:contract, :for_ecf, banded_fee_structure:) }

    before { render_inline(component) }

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
        headings: ["Band", "Min", "Max", "Fee per declaration", "Output fee", "Service fee"],
        rows: [
          ["Band A", 1, 50, "£100.00", "75%", "25%"],
          ["Band B", 51, 100, "£100.00", "75%", "25%"],
          ["Band C", 101, 150, "£100.00", "75%", "25%"]
        ]
      )
    end
  end

  context "for `ittecf_ectp` contracts" do
    let(:contract) { FactoryBot.build_stubbed(:contract, :for_ittecf_ectp, banded_fee_structure:) }

    before { render_inline(component) }

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
        headings: ["Band", "Min", "Max", "Fee per declaration", "Output fee", "Service fee"],
        rows: [
          ["Band A", 1, 50, "£100.00", "75%", "25%"],
          ["Band B", 51, 100, "£100.00", "75%", "25%"],
          ["Band C", 101, 150, "£100.00", "75%", "25%"]
        ]
      )
    end
  end
end
