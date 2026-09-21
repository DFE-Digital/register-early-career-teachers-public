RSpec.describe "Product team users can paste inline CSV to fix data" do
  include ActiveJob::TestHelper

  before do
    freeze_time
    setup_data_to_fix
  end

  it "validates CSV and redirects to preview step" do
    given_i_am_signed_in_as_a_product_team_user
    when_i_open_the_tools_tab
    and_i_choose_data_fixes
    then_i_see_the_csv_form

    and_i_continue
    then_i_see_an_error("CSV can’t be blank")

    given_i_input_a_csv_string_with(invalid_csv_rows)
    and_i_continue
    then_i_see_an_error("CSV is malformed")

    given_i_input_a_csv_string_with(invalid_headers_rows)
    and_i_continue
    then_i_see_an_error("CSV has invalid headers")

    given_i_input_a_csv_string_with(valid_rows)
    and_i_continue
    then_i_am_taken_to_the_preview_step
    and_parsed_valid_rows_are_displayed

    given_i_preview_the_changes
    then_i_see_an_error_for_each_invalid_row

    given_i_go_back
    then_i_am_taken_to_the_csv_step
    and_the_csv_string_is_displayed_for(valid_rows)

    given_i_input_a_csv_string_with(processable_rows)
    and_i_continue
    then_i_am_taken_to_the_preview_step
    and_parsed_processable_rows_are_displayed

    given_i_preview_the_changes
    then_i_am_taken_to_the_verify_step
    and_proposed_processed_changes_are_displayed

    when_i_verify_the_changes
    then_i_see_an_error("Add a note or enter the Zendesk ticket number")

    given_i_enter_a_reason_for_the_changes
    perform_enqueued_jobs { and_i_verify_the_changes }
    then_i_am_taken_to_the_confirmation_step
    and_confirmed_changes_are_displayed

    given_i_choose_to_fix_more_data
    then_i_am_taken_to_the_csv_step
    and_the_csv_form_is_empty
  end

private

  def setup_data_to_fix
    @ect_at_school_period = FactoryBot.create(:ect_at_school_period)
    @teacher = @ect_at_school_period.teacher
  end

  def given_i_am_signed_in_as_a_product_team_user
    sign_in_as_dfe_user(role: :product_team)
  end

  def when_i_open_the_tools_tab
    page.goto("/admin")
    page.get_by_role("link", name: "Tools", exact: true).click
    expect(page).to have_path("/admin/tools")
  end

  def and_i_choose_data_fixes
    page.get_by_role("link", name: "Data fixes", exact: true).click
  end

  def then_i_see_the_csv_form
    heading = page.get_by_role("heading", name: "Enter data fixes in CSV format")
    expect(heading).to be_visible
  end

  def and_i_continue
    page.get_by_role("button", name: "Continue", exact: true).click
  end
  alias_method :given_i_preview_the_changes, :and_i_continue

  def then_i_see_an_error(error_message)
    error_summary = page.locator(".govuk-error-summary")
    expect(error_summary).to have_text(error_message)
  end

  def then_i_am_taken_to_the_preview_step
    expect(page).to have_path("/admin/data_fixes/preview")
  end

  def then_i_see_an_error_for_each_invalid_row
    row1_error_message = <<~TXT.squish
      Row 1: Validation failed: TRN Teacher reference number must include at
      least 5 digits
    TXT
    row2_error_message = "Row 2: Unknown action 'destroy'"
    then_i_see_an_error(row1_error_message)
    then_i_see_an_error(row2_error_message)
  end

  def given_i_go_back
    page.get_by_role("link", name: "Back", exact: true).click
  end

  def then_i_am_taken_to_the_csv_step
    expect(page).to have_path("/admin/data_fixes/csv")
  end

  def csv_input = page.get_by_label("Enter data fixes in CSV format")
  def given_i_input_a_csv_string_with(rows) = csv_input.fill(rows)
  def invalid_csv_rows = <<~ROWS
    object_type,object_id,action,attributes
    something,1,create,"unterminated,string
  ROWS
  def invalid_headers_rows = <<~ROWS
    object_type,object_id,action,wrong_header
    teacher,#{@teacher.id},update,"trn,1"
    ect_at_school_period,#{@ect_at_school_period.id},destroy,""
  ROWS
  def valid_rows = <<~ROWS
    object_type,object_id,action,attributes
    teacher,#{@teacher.id},update,"trn,1"
    ect_at_school_period,#{@ect_at_school_period.id},destroy,""
  ROWS
  def processable_rows = <<~ROWS
    object_type,object_id,action,attributes
    teacher,#{@teacher.id},update,"trn,1234567"
    ect_at_school_period,#{@ect_at_school_period.id},delete,""
  ROWS

  def and_the_csv_string_is_displayed_for(rows)
    expect(csv_input.input_value).to eq(rows)
  end

  def and_parsed_valid_rows_are_displayed
    and_table_is_displayed(
      "Parsed rows",
      header: %w[object_type object_id action attributes],
      rows: [
        ["teacher", @teacher.id.to_s, "update", "trn,1"],
        ["ect_at_school_period", @ect_at_school_period.id.to_s, "destroy", ""]
      ]
    )
  end

  def and_parsed_processable_rows_are_displayed
    and_table_is_displayed(
      "Parsed rows",
      header: %w[object_type object_id action attributes],
      rows: [
        ["teacher", @teacher.id.to_s, "update", "trn,1234567"],
        ["ect_at_school_period", @ect_at_school_period.id.to_s, "delete", ""]
      ]
    )
  end

  def and_table_is_displayed(caption, header:, rows:)
    table = page.get_by_role("table", name: caption)
    header.each.with_index do |th, index|
      expect(table.locator("th").nth(index)).to have_text(th)
    end
    expect(table.locator("tbody tr")).to have_count(rows.size)
    rows.each.with_index do |row, row_index|
      row.each.with_index do |cell, cell_index|
        td = table.locator("tbody tr").nth(row_index).locator("td").nth(cell_index)
        expect(td).to have_text(cell)
      end
    end
  end

  def then_i_am_taken_to_the_verify_step
    expect(page).to have_path("/admin/data_fixes/verify")
  end

  def and_proposed_processed_changes_are_displayed
    and_summary_card_is_displayed(
      @teacher.to_global_id,
      rows: { "Action" => "update", "trn" => [@teacher.trn, "1234567"] }
    )
    and_summary_card_is_displayed(
      @ect_at_school_period.to_global_id,
      rows: { "Action" => "delete" }
    )
  end

  def and_summary_card_is_displayed(heading, rows:)
    summary_card = page.locator(".govuk-summary-card", hasText: heading)
    expect(summary_card.locator("dl div.govuk-summary-list__row")).to have_count(rows.size)
    rows.each_with_index do |(key, value), index|
      summary_list_row = summary_card.locator("dl div.govuk-summary-list__row").nth(index)
      expect(summary_list_row.locator("dt")).to have_text(key)
      summary_list_row_value = summary_list_row.locator("dd")
      if value.is_a?(Array)
        expect(summary_list_row_value.locator("del")).to have_text(value.first)
        expect(summary_list_row_value.locator("ins")).to have_text(value.second)
      else
        expect(summary_list_row_value).to have_text(value)
      end
    end
  end

  def when_i_verify_the_changes
    page.get_by_role("button", name: "Confirm changes", exact: true).click
  end
  alias_method :and_i_verify_the_changes, :when_i_verify_the_changes

  def given_i_enter_a_reason_for_the_changes
    input = page.get_by_label("Add a note to explain why you're making this change")
    input.fill("This is a test reason")
  end

  def then_i_am_taken_to_the_confirmation_step
    expect(page).to have_path("/admin/data_fixes/confirmation")
  end

  alias_method :and_confirmed_changes_are_displayed, :and_proposed_processed_changes_are_displayed

  def given_i_choose_to_fix_more_data
    page.get_by_role("link", name: "Fix more data", exact: true).click
  end

  def and_the_csv_form_is_empty
    expect(csv_input.input_value).to eq("")
  end
end
