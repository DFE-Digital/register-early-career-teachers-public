RSpec.describe "Assigning a new induction tutor", :enable_schools_interface do
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
      then_i_am_taken_to_the_new_induction_tutor_page
      and_the_navigation_bar_is_not_visible

      when_i_enter_invalid_details_for_the_induction_tutor
      and_i_click_continue
      then_i_should_see_error_messages_indicating_what_i_need_to_fix

      when_i_enter_valid_details_for_the_induction_tutor
      and_i_click_continue
      then_i_should_be_taken_to_the_check_answers_page
      and_the_navigation_bar_is_not_visible

      when_i_click_cancel_and_go_back
      then_i_am_taken_to_the_new_induction_tutor_page
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

  def and_there_are_contract_periods
    @previous_contract_period = FactoryBot.create(:contract_period, :previous, :with_schedules)
    @current_contract_period = FactoryBot.create(:contract_period, :current, :with_schedules)
  end

  def and_i_sign_in_as_that_school_user
    sign_in_as_school_user(school: @school)
  end

  def and_the_details_are_confirmed_for_the_previous_contract_period
    @school.update(induction_tutor_last_nominated_in: @previous_contract_period)
  end

  def and_the_details_are_confirmed_for_the_current_contract_period
    @school.update(induction_tutor_last_nominated_in: @current_contract_period)
  end

  def then_i_am_taken_to_the_new_induction_tutor_page
    expect(page).to have_path("/school/induction-tutor/new-induction-tutor/edit")
    expect(page.get_by_text("Tell us your induction tutor")).to be_visible
  end

  def and_the_navigation_bar_is_not_visible
    expect(page.locator(".govuk-service-navigation__wrapper")).not_to be_visible
  end

  def and_the_navigation_bar_is_visible
    expect(page.locator(".govuk-service-navigation__wrapper")).to be_visible
  end

  def and_the_data_i_entered_is_saved
    expect(page.get_by_label("Full name").input_value).to eq("New Name")
    expect(page.get_by_label("Email").input_value).to eq("new.name@example.com")
  end

  def and_i_click_continue
    page.get_by_role("button", name: "Continue").click
  end

  def when_i_click_continue_from_confirmation_page
    page.get_by_role("link", name: "Continue").click
  end

  def then_i_should_be_taken_to_the_confirmation_page
    expect(page).to have_path("/school/induction-tutor/new-induction-tutor/confirmation")
  end

  def and_i_should_see_a_confirmation_message
    expect(page.get_by_text("New Name is your school’s induction tutor")).to be_visible
  end

  def then_i_should_see_the_school_home_page
    expect(page).to have_path("/school/home/ects")
    expect(page.get_by_text("Early career teachers (ECT)")).to be_visible
  end

  def and_the_induction_tutor_details_should_have_changed
    expect(@school.reload.induction_tutor_name).to eq("New Name")
    expect(@school.induction_tutor_email).to eq("new.name@example.com")
  end

  def and_the_induction_tutor_details_should_be_confirmed_in_the_current_contract_period
    @school.reload

    expect(@school.induction_tutor_last_nominated_in).to be_present
    expect(@school.induction_tutor_last_nominated_in.year).to eq(@current_contract_period.year)
  end

  def when_i_enter_invalid_details_for_the_induction_tutor
    page.get_by_label("Email").fill("invalid-email")
  end

  def then_i_should_see_error_messages_indicating_what_i_need_to_fix
    expect(page.get_by_role("heading", name: "There is a problem")).to be_visible
    expect(page.locator(".govuk-error-summary a").and(page.get_by_text("Enter an email address in the correct format, like name@example.com"))).to be_visible
  end

  def when_i_enter_valid_details_for_the_induction_tutor
    page.get_by_label("Full name").fill("New Name")
    page.get_by_label("Email").fill("new.name@example.com")
  end

  def then_i_should_be_taken_to_the_check_answers_page
    expect(page).to have_path("/school/induction-tutor/new-induction-tutor/check-answers")
  end

  def and_the_new_name_and_email_should_be_displayed_on_the_check_answers_page
    expect(page.get_by_text("new.name@example.com")).to be_visible
    expect(page.get_by_text("New Name")).to be_visible
  end

  def when_i_click_cancel_and_go_back
    page.get_by_role("link", name: "Cancel and go back").click
  end

  def when_i_click_confirm
    page.get_by_role("button", name: "Confirm induction tutor").click
  end
end
