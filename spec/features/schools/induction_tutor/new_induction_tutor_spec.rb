RSpec.describe "Assigning a new induction tutor", :enable_schools_interface do
  include Features::InductionTutorHelpers

  before do
    given_there_is_a_school_with_no_induction_tutor_in_the_service
    and_there_are_contract_periods
    and_i_sign_in_as_that_school_user
  end

  context "enable_induction_tutor_prompt flag is not enabled" do
    scenario "signing in as a school user takes you to the school home page" do
      then_i_should_see_the_school_home_page
      and_the_navigation_bar_is_visible
    end
  end

  context "enable_induction_tutor_prompt flag is enabled", :enable_induction_tutor_prompt do
    scenario "the existing details have never been confirmed" do
      then_i_am_taken_to_the_wizard_start_page
      and_the_navigation_bar_is_not_visible

      when_i_enter_invalid_details_for_the_induction_tutor
      and_i_click_continue
      then_i_should_see_error_messages_indicating_what_i_need_to_fix

      when_i_enter_valid_details_for_the_induction_tutor
      and_i_click_continue
      then_i_should_be_taken_to_the_check_answers_page
      and_the_navigation_bar_is_not_visible

      when_i_click_cancel_and_go_back
      then_i_am_taken_to_the_wizard_start_page
      and_the_data_i_entered_is_saved
      and_the_navigation_bar_is_not_visible

      when_i_enter_valid_details_for_the_induction_tutor
      and_i_click_continue
      then_i_should_be_taken_to_the_check_answers_page

      when_i_click_confirm
      then_i_should_be_taken_to_the_confirmation_page
      and_i_should_see_a_confirmation_message
      and_the_navigation_bar_is_visible

      when_i_click_continue_from_confirmation_page
      then_i_should_see_the_school_home_page
      and_the_navigation_bar_is_visible

      and_the_induction_tutor_details_should_have_changed
      and_the_induction_tutor_details_should_be_confirmed_in_the_current_contract_period
    end
  end

  def given_there_is_a_school_with_no_induction_tutor_in_the_service
    @school = FactoryBot.create(:school, urn: "1234567")
  end

  def and_i_should_see_a_confirmation_message
    expect(page.get_by_text("New Name is your school’s induction tutor")).to be_visible
  end

  def base_page
    "/school/induction-tutor/new-induction-tutor"
  end
end
