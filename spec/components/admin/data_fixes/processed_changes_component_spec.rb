RSpec.describe Admin::DataFixes::ProcessedChangesComponent, type: :component do
  subject(:component) { described_class.new(changes) }

  before { render_inline(component) }

  context "when changes is nil" do
    let(:changes) { nil }

    it "renders nothing" do
      expect(rendered_content).to be_empty
    end
  end

  context "when changes is empty" do
    let(:changes) { [] }

    it "renders nothing" do
      expect(rendered_content).to be_empty
    end
  end

  context "when there are changes" do
    let(:changes) do
      [
        {
          "gid" => "Teacher/1",
          "action" => "delete",
          "changes" => []
        },
        {
          "gid" => "Teacher/2",
          "action" => "update",
          "changes" => {
            "trn" => ["", "1234567"],
            "corrected_name" => ["something", ""]
          }
        },
      ]
    end

    it "renders a summary card for each change" do
      expect(page).to have_css(".govuk-summary-card", count: 2)

      expect(page).to have_css(".govuk-summary-card h2", text: "Teacher/1")
      summary_card1 = page.find(".govuk-summary-card", text: "Teacher/1")
      expect(summary_card1).to have_summary_list_row("Action", value: "delete")

      expect(page).to have_css(".govuk-summary-card h2", text: "Teacher/2")
      summary_card2 = page.find(".govuk-summary-card", text: "Teacher/2")
      expect(summary_card2).to have_summary_list_row("Action", value: "update")
      expect(summary_card2).to have_summary_list_row(
        "trn",
        value: "del",
        matcher: [:has_css?, { text: "Nil" }]
      )
      expect(summary_card2).to have_summary_list_row(
        "trn",
        value: "ins",
        matcher: [:has_css?, { text: "1234567" }]
      )
      expect(summary_card2).to have_summary_list_row(
        "corrected_name",
        value: "del",
        matcher: [:has_css?, { text: "something" }]
      )
      expect(summary_card2).to have_summary_list_row(
        "corrected_name",
        value: "ins",
        matcher: [:has_css?, { text: "Nil" }]
      )
    end
  end
end
