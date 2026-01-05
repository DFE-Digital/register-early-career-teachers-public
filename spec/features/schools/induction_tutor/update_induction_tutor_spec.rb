RSpec.describe "Assigning a new induction tutor", :enable_schools_interface do
  include Features::InductionTutorHelpers

  scenario "changing the existing details" do
    given_there_is_a_school_with_an_induction_tutor_in_the_service
    and_there_are_contract_periods
    and_the_details_are_confirmed_for_the_current_contract_period
    and_i_sign_in_as_that_school_user

    when_i_view_the_current_induction_tutor_details_page
    and_i_click_change_induction_tutor_details
    then_i_am_taken_to_the_wizard_start_page
    and_there_is_a_back_link
    and_there_is_a_link_to_cancel_and_go_back

    when_i_enter_invalid_details_for_the_induction_tutor
    and_i_click_continue
    then_i_should_see_error_messages_indicating_what_i_need_to_fix

    when_i_enter_valid_details_for_the_induction_tutor
    and_i_click_continue
    then_i_should_be_taken_to_the_check_answers_page
    and_there_is_a_link_to_cancel_and_go_back_to_the_induction_tutor_details

    when_i_click_back
    then_i_am_taken_to_the_wizard_start_page
    and_the_data_i_entered_is_saved

    when_i_enter_valid_details_for_the_induction_tutor
    and_i_click_continue
    then_i_should_be_taken_to_the_check_answers_page

    when_i_click_confirm_change
    then_i_should_be_taken_to_the_confirmation_page
    and_i_should_see_a_confirmation_message

    when_i_click_continue_from_confirmation_page
    then_i_should_see_the_ects_home_page
    and_the_induction_tutor_details_should_have_changed
    and_the_induction_tutor_details_should_be_confirmed_in_the_current_contract_period
  end

  def given_there_is_a_school_with_an_induction_tutor_in_the_service
    @school = FactoryBot.create(:school, :with_induction_tutor, urn: "1234567")
  end

  def when_i_view_the_current_induction_tutor_details_page
    page.get_by_role("link", name: "Induction tutor").click
  end

  def and_i_click_change_induction_tutor_details
    page.get_by_role("link", name: "Change induction tutor details").click
  end

  def and_there_is_a_back_link
    expect(page.locator("a.govuk-back-link")).to have_attribute("href", "/school/home/induction-tutor")
  end

  def when_i_click_back
    page.locator("a.govuk-back-link").click
  end

  def and_there_is_a_link_to_cancel_and_go_back
    expect(page.get_by_role("link", name: "Cancel and go back to induction tutor details")).to have_attribute("href", "/school/home/induction-tutor")
  end

  def and_there_is_a_link_to_cancel_and_go_back_to_the_induction_tutor_details
    expect(page.get_by_role("link", name: "Cancel and go back to induction tutor details")).to have_attribute("href", "/school/home/induction-tutor")
  end

  def when_i_click_confirm_change
    page.get_by_role("button", name: "Confirm change").click
  end

  def and_i_should_see_a_confirmation_message
    expect(page.get_by_text("You’ve changed your school’s induction tutor to New Name")).to be_visible
  end

  def then_i_should_see_the_ects_home_page
    expect(page).to have_path("/school/home/ects")
  end

  def base_page
    "/school/induction-tutor/update-induction-tutor"
  end
end
