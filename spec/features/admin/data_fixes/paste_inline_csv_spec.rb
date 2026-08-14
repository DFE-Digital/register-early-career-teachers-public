RSpec.describe "Product team users can paste inline CSV to fix data" do
  before { enable_admin_data_fixes_feature_flag }

  it "validates CSV and redirects to preview step" do
    given_i_am_signed_in_as_a_product_team_user
    when_i_visit_the_admin_data_fixes_csv_page
    then_i_see_the_csv_form

    and_i_continue
    then_i_see_an_error("CSV can’t be blank")

    given_i_input_an_invalid_csv_string
    and_i_continue
    then_i_see_an_error("CSV is malformed")

    given_i_input_a_valid_csv_string_with_invalid_headers
    and_i_continue
    then_i_see_an_error("CSV has invalid headers")

    given_i_input_a_valid_csv_string_with_correct_headers
    and_i_continue
    then_i_am_taken_to_the_preview_page
    and_the_preview_is_displayed
  end

private

  def enable_admin_data_fixes_feature_flag
    allow(Rails.application.config).to receive(:enable_admin_data_fixes).and_return(true)
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

  def given_i_input_an_invalid_csv_string
    invalid_csv_rows = <<~ROWS
      object_type,object_id,action,attributes
      something,1,create,"unterminated,string
    ROWS
    input_csv_string(invalid_csv_rows)
  end

  def input_csv_string(rows)
    page.get_by_label("Enter data fixes in CSV format").fill(rows)
  end

  def and_i_continue
    page.get_by_role("button", name: "Continue", exact: true).click
  end

  def then_i_see_an_error(error_message)
    error_summary = page.locator(".govuk-error-summary")
    expect(error_summary).to have_text(error_message)
  end

  def given_i_input_a_valid_csv_string_with_invalid_headers
    invalid_headers_rows = <<~ROWS
      object_type,object_id,action,wrong_header
      something,1,create,"attribute1,value1,attribute2,value2"
      anotherthing,2,destroy,""
    ROWS
    input_csv_string(invalid_headers_rows)
  end

  def given_i_input_a_valid_csv_string_with_correct_headers
    valid_rows = <<~ROWS
      object_type,object_id,action,attributes
      something,1,create,"attribute1,value1,attribute2,value2"
      another_thing,2,destroy,""
    ROWS
    input_csv_string(valid_rows)
  end

  def then_i_am_taken_to_the_preview_page
    expect(page).to have_path("/admin/data_fixes/preview")
  end

  def and_the_preview_is_displayed
    heading = page.get_by_role("heading", name: "Preview the proposed data fix")
    expect(heading).to be_visible
  end
end
