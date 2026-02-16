RSpec.describe "Confirming an existing induction tutor", :enable_schools_interface do
  include Features::InductionTutorHelpers

  before do
    given_there_is_a_school_in_the_service
    and_there_are_contract_periods
    and_the_school_has_an_existing_induction_tutor
  end

  scenario "the details have been confirmed in the current contract period" do
    and_the_details_are_confirmed_for_the_current_contract_period
    and_i_sign_in_as_that_school_user
    then_i_should_see_the_school_home_page
    and_the_navigation_bar_is_visible
  end

  scenario "the existing details have never been confirmed" do
    and_the_details_are_not_confirmed
    and_i_sign_in_as_that_school_user
    then_i_am_taken_to_the_wizard_start_page
    and_the_navigation_bar_is_not_visible

    when_i_confirm_that_the_existing_details_are_correct
    and_i_click_continue
    then_i_should_be_taken_to_the_confirmation_page
    and_the_navigation_bar_is_visible
    and_i_should_see_a_confirmation_message

    when_i_click_continue_from_confirmation_page
    then_i_should_see_the_school_home_page
    and_the_navigation_bar_is_visible
    and_the_induction_tutor_details_should_not_change
    and_the_induction_tutor_details_should_be_confirmed_in_the_current_contract_period
  end

  scenario "the existing were confirmed last contract period" do
    and_the_details_are_confirmed_for_the_previous_contract_period
    and_i_sign_in_as_that_school_user
    then_i_am_taken_to_the_wizard_start_page
    and_the_navigation_bar_is_not_visible

    when_i_confirm_that_the_existing_details_are_correct
    and_i_click_continue
    then_i_should_be_taken_to_the_confirmation_page
    and_the_navigation_bar_is_visible
    and_i_should_see_a_confirmation_message

    when_i_click_continue_from_confirmation_page
    then_i_should_see_the_school_home_page
    and_the_navigation_bar_is_visible
    and_the_induction_tutor_details_should_not_change
    and_the_induction_tutor_details_should_be_confirmed_in_the_current_contract_period
  end

  scenario "changing the existing details" do
    and_i_sign_in_as_that_school_user
    then_i_am_taken_to_the_wizard_start_page
    and_the_navigation_bar_is_not_visible

    when_i_click_no_these_details_are_incorrect
    and_i_click_continue
    then_i_should_see_an_error_message_indicating_i_must_change_the_details

    when_i_change_the_induction_tutor_email_to_an_invalid_email
    and_i_click_continue
    then_i_should_see_an_error_message_indicating_the_email_is_invalid

    when_i_change_the_induction_tutor_email
    and_i_click_continue
    then_i_should_be_taken_to_the_check_answers_page
    and_the_navigation_bar_is_not_visible
    and_the_new_email_should_be_displayed_on_the_check_answers_page

    when_i_click_cancel_and_go_back
    then_i_am_taken_to_the_wizard_start_page
    and_the_navigation_bar_is_not_visible
    and_the_data_i_entered_is_saved

    when_i_click_no_these_details_are_incorrect
    and_i_enter_valid_details
    and_i_click_continue
    then_i_should_be_taken_to_the_check_answers_page
    and_the_navigation_bar_is_not_visible
    and_the_new_name_and_email_should_be_displayed_on_the_check_answers_page

    when_i_click_confirm_change
    then_i_should_be_taken_to_the_confirmation_page
    and_the_navigation_bar_is_visible
    and_it_should_confirm_the_new_details

    when_i_click_continue_from_confirmation_page
    then_i_should_see_the_school_home_page
    and_the_navigation_bar_is_visible
    and_the_induction_tutor_details_should_have_changed
    and_the_induction_tutor_details_should_be_confirmed_in_the_current_contract_period
  end
  
  def given_there_is_a_school_in_the_service
    @school = FactoryBot.create(:school, :with_unconfirmed_induction_tutor, urn: "1234567")
  end

  def and_the_school_has_an_existing_induction_tutor
    @school.induction_tutor_name = "Alastair Sim"
    @school.induction_tutor_email = "alastair.sim@st-trinians.org.uk"
    @school.save!
  end

  def and_the_details_are_not_confirmed
    @school.induction_tutor_last_nominated_in = nil
  end

  def and_the_data_i_entered_is_saved
    expect(page.get_by_role("radio", name: "No")).to be_checked
    expect(page.get_by_label("Email").input_value).to eq("new.name@example.com")
  end

  def when_i_confirm_that_the_existing_details_are_correct
    page.get_by_role("radio", name: "Yes").click
  end

  def when_i_click_no_these_details_are_incorrect
    page.get_by_role("radio", name: "No").click
  end

  def and_i_should_see_a_confirmation_message
    expect(page.get_by_text("You’ve confirmed Alastair Sim will continue as your school’s induction tutor")).to be_visible
  end

  def and_it_should_confirm_the_new_details
    expect(page.get_by_text("You’ve changed your school’s induction tutor to New Name")).to be_visible
  end

  def and_the_induction_tutor_details_should_not_change
    expect(@school.reload.induction_tutor_name).to eq("Alastair Sim")
    expect(@school.induction_tutor_email).to eq("alastair.sim@st-trinians.org.uk")
  end

  def then_i_should_see_an_error_message_indicating_i_must_change_the_details
    expect(page.get_by_text("You must change the induction tutor details or confirm they are correct")).to be_visible
  end

  def when_i_change_the_induction_tutor_email_to_an_invalid_email
    page.get_by_label("Email").fill("not-an-email")
  end

  def then_i_should_see_an_error_message_indicating_the_email_is_invalid
    expect(page.get_by_role("heading", name: "There is a problem")).to be_visible
    expect(page.locator(".govuk-error-summary a").and(page.get_by_text("Enter an email address in the correct format, like name@example.com"))).to be_visible
  end

  def when_i_change_the_induction_tutor_email
    page.get_by_label("Email").fill("new.name@example.com")
  end

  def and_the_new_email_should_be_displayed_on_the_check_answers_page
    expect(page.get_by_text("new.name@example.com")).to be_visible
    expect(page.get_by_text(@school.induction_tutor_name)).to be_visible
  end

  def when_i_click_confirm_change
    page.get_by_role("button", name: "Confirm change").click
  end

  def base_page
    "/school/induction-tutor/confirm-existing-induction-tutor"
  end
end
