RSpec.describe "Product team users can paste inline CSV to fix data" do
  before do
    freeze_time
    enable_admin_data_fixes_feature_flag
    setup_data_to_fix
  end

  it "validates CSV and redirects to preview step" do
    given_i_am_signed_in_as_a_product_team_user
    when_i_visit_the_admin_data_fixes_csv_page
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
    then_the_proposed_processed_changes_are_displayed
  end

private

  def enable_admin_data_fixes_feature_flag
    allow(Rails.application.config).to receive(:enable_admin_data_fixes).and_return(true)
  end

  def setup_data_to_fix
    @ect_at_school_period = FactoryBot.create(:ect_at_school_period)
    @teacher = @ect_at_school_period.teacher
  end

  def given_i_am_signed_in_as_a_product_team_user
    sign_in_as_dfe_user(role: :product_team)
  end

  def when_i_visit_the_admin_data_fixes_csv_page
    page.goto("/admin/data_fixes/csv")
  end

  def then_i_see_the_csv_form
    heading = page.get_by_role("heading", name: "Enter data fixes in CSV format")
    expect(heading).to be_visible
  end

  def and_i_continue
    page.get_by_role("button", name: "Continue", exact: true).click
  end

  def then_i_see_an_error(error_message)
    error_summary = page.locator(".govuk-error-summary")
    expect(error_summary).to have_text(error_message)
  end

  def then_i_am_taken_to_the_preview_step
    expect(page).to have_path("/admin/data_fixes/preview")
  end

  def given_i_preview_the_changes
    page.get_by_role("button", name: "Preview", exact: true).click
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
    parsed_row1 = <<~TXT.squish
      {"object_type" => "teacher",
      "object_id" => "#{@teacher.id}",
      "action" => "update",
      "attributes" => "trn,1"}
    TXT
    row1 = page.locator("li", hasText: parsed_row1)
    expect(row1).to be_visible
    parsed_row2 = <<~TXT.squish
      {"object_type" => "ect_at_school_period",
      "object_id" => "#{@ect_at_school_period.id}",
      "action" => "destroy",
      "attributes" => ""}
    TXT
    row2 = page.locator("li", hasText: parsed_row2)
    expect(row2).to be_visible
  end

  def and_parsed_processable_rows_are_displayed
    parsed_row1 = <<~TXT.squish
      {"object_type" => "teacher",
      "object_id" => "#{@teacher.id}",
      "action" => "update",
      "attributes" => "trn,1234567"}
    TXT
    row1 = page.locator("li", hasText: parsed_row1)
    expect(row1).to be_visible
    parsed_row2 = <<~TXT.squish
      {"object_type" => "ect_at_school_period",
      "object_id" => "#{@ect_at_school_period.id}",
      "action" => "delete",
      "attributes" => ""}
    TXT
    row2 = page.locator("li", hasText: parsed_row2)
    expect(row2).to be_visible
  end

  def then_i_am_taken_to_the_verify_step
    expect(page).to have_path("/admin/data_fixes/verify")
  end

  def then_the_proposed_processed_changes_are_displayed
    proposed_row1 = <<~TXT.squish
      {"record_identifier" => "Teacher(##{@teacher.id})",
      "action" => "update",
      "changes" => {"trn" => ["#{@teacher.trn}", "1234567"]}
    TXT
    row1 = page.locator("li", hasText: proposed_row1)
    expect(row1).to be_visible
    proposed_row2 = <<~TXT.squish
      {"record_identifier" => "ECTAtSchoolPeriod(##{@ect_at_school_period.id})",
      "action" => "delete",
      "changes" => {}}
    TXT
    row2 = page.locator("li", hasText: proposed_row2)
    expect(row2).to be_visible
  end
end
