RSpec.describe "Confirming an existing induction tutor", :enable_schools_interface, :js do
  before do
    given_there_is_a_school_in_the_service
    and_the_school_has_an_existing_induction_tutor
    and_there_are_contract_periods
    and_i_sign_in_as_that_school_user
  end

  after do
    and_i_click_continue
    then_i_should_be_taken_to_the_confirmation_page
    and_i_click_continue_from_confirmation_page
    then_i_should_see_the_school_home_page
    and_the_induction_tutor_details_should_be_confirmed_in_the_current_contract_period

    when_i_login_again
    then_i_should_see_the_school_home_page
  end

  scenario "the existing have never been confirmed" do
    and_the_details_are_not_confirmed
    then_i_am_taken_to_the_confirm_existing_induction_tutor_page
    when_i_confirm_that_the_existing_details_are_correct
  end

  xscenario "the existing were confirmed last contract period" do
    and_the_details_are_confirmed_for_the_previous_contract_period
    then_i_am_taken_to_the_confirm_existing_induction_tutor_page
    when_i_confirm_that_the_existing_details_are_correct
  end

  xscenario "changing the existing details" do
    when_i_click_no_these_details_are_incorrect
    and_i_click_continue
    then_i_should_see_an_error_message_indicating_i_must_change_the_details
    when_i_change_the_induction_tutor_email_to_an_invalid_email
    and_i_click_continue
    then_i_should_see_an_error_message_indicating_the_email_is_invalid
    when_i_change_the_induction_tutor_name_and_email
    and_i_click_continue
    then_i_should_be_taken_to_the_check_answers_page
    and_the_new_details_should_be_displayed_on_the_check_answers_page
  end

  def given_there_is_a_school_in_the_service
    @school = FactoryBot.create(:school, urn: "1234567")
  end

  def and_there_are_contract_periods
    @previous_contract_period = FactoryBot.create(:contract_period, :previous, :with_schedules)
    @current_contract_period = FactoryBot.create(:contract_period, :current, :with_schedules)
  end

  def and_the_school_has_an_existing_induction_tutor
    @school.induction_tutor_name = "Alastair Sim"
    @school.induction_tutor_email = "alastair.sim@st-trinians.co.uk"
    @school.save!
  end

  def and_i_sign_in_as_that_school_user
    sign_in_as_school_user(school: @school)
  end

  def and_the_details_are_not_confirmed
    @school.induction_tutor_last_nominated_in_year = nil
  end

  def and_the_details_are_confirmed_for_the_previous_contract_period
    @school.induction_tutor_last_nominated_in_year = @previous_contract_period
  end

  def then_i_am_taken_to_the_confirm_existing_induction_tutor_page
    expect(page).to have_path("/school/confirm-existing-induction-tutor/edit")
    expect(page.get_by_text("Confirm induction tutor details")).to be_visible
  end

  def when_i_confirm_that_the_existing_details_are_correct
    page.get_by_role("radio", name: "Yes").click
  end

  def and_i_click_continue
    page.get_by_role("button", name: "Continue").click
  end

  def and_i_click_continue_from_confirmation_page
    page.get_by_role("link", name: "Continue").click
  end

  def then_i_should_be_taken_to_the_confirmation_page
    expect(page).to have_path("/school/confirm-existing-induction-tutor/confirmation")
    expect(page.get_by_text("You've confirmed Alastair Sim will continue as your school's induction tutor")).to be_visible
  end

  def then_i_should_see_the_school_home_page
    expect(page).to have_path("/school/home/ects")
    expect(page.get_by_text("Early career teachers (ECT)")).to be_visible
  end

  def and_the_induction_tutor_details_should_be_confirmed_in_the_current_contract_period
    @school.reload

    expect(@school.induction_tutor_last_nominated_in_year).to be_present
    expect(@school.induction_tutor_last_nominated_in_year.year).to eq(@current_contract_period.year)
  end

  # page.screenshot(path: "tmp/screenshot.png")
end
