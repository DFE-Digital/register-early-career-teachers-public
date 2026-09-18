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
          "gid" => "gid://app/ECTAtSchoolPeriod/1",
          "action" => "delete",
          "changes" => {}
        },
        {
          "gid" => "gid://app/Teacher/1",
          "action" => "update",
          "changes" => {
            "trn" => ["", "1234567"],
            "corrected_name" => ["something", ""],
            "trs_first_name" => [nil, "Test"],
            "trs_last_name" => ["Person", nil],
            "some_boolean" => [false, true],
            "some_other_boolean" => [true, false],
            "some_integer" => [0, 100],
            "some_other_integer" => [100, 0]
          }
        },
      ]
    end

    it "renders a summary card for each change" do
      expect(page).to have_css(".govuk-summary-card", count: 2)

      expect(page).to have_css(".govuk-summary-card h2", text: "gid://app/ECTAtSchoolPeriod/1")
      summary_card1 = page.find(".govuk-summary-card", text: "gid://app/ECTAtSchoolPeriod/1")
      expect(summary_card1).to have_summary_list_row("Action", value: "delete")

      expect(page).to have_css(".govuk-summary-card h2", text: "gid://app/Teacher/1")
      summary_card2 = page.find(".govuk-summary-card", text: "gid://app/Teacher/1")
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
      expect(summary_card2).to have_summary_list_row(
        "trs_first_name",
        value: "del",
        matcher: [:has_css?, { text: "Nil" }]
      )
      expect(summary_card2).to have_summary_list_row(
        "trs_first_name",
        value: "ins",
        matcher: [:has_css?, { text: "Test" }]
      )
      expect(summary_card2).to have_summary_list_row(
        "trs_last_name",
        value: "del",
        matcher: [:has_css?, { text: "Person" }]
      )
      expect(summary_card2).to have_summary_list_row(
        "trs_last_name",
        value: "ins",
        matcher: [:has_css?, { text: "Nil" }]
      )
      expect(summary_card2).to have_summary_list_row(
        "some_boolean",
        value: "del",
        matcher: [:has_css?, { text: "false" }]
      )
      expect(summary_card2).to have_summary_list_row(
        "some_boolean",
        value: "ins",
        matcher: [:has_css?, { text: "true" }]
      )
      expect(summary_card2).to have_summary_list_row(
        "some_other_boolean",
        value: "del",
        matcher: [:has_css?, { text: "true" }]
      )
      expect(summary_card2).to have_summary_list_row(
        "some_other_boolean",
        value: "ins",
        matcher: [:has_css?, { text: "false" }]
      )
      expect(summary_card2).to have_summary_list_row(
        "some_integer",
        value: "del",
        matcher: [:has_css?, { text: "0" }]
      )
      expect(summary_card2).to have_summary_list_row(
        "some_integer",
        value: "ins",
        matcher: [:has_css?, { text: "100" }]
      )
      expect(summary_card2).to have_summary_list_row(
        "some_other_integer",
        value: "del",
        matcher: [:has_css?, { text: "100" }]
      )
      expect(summary_card2).to have_summary_list_row(
        "some_other_integer",
        value: "ins",
        matcher: [:has_css?, { text: "0" }]
      )
    end
  end
end
