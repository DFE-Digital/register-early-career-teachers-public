RSpec.describe "Registering an ECT", :enable_schools_interface do
  include_context "test trs api client that finds a teacher and nothing"

  scenario "Teacher with national insurance number is not found" do
    given_i_am_logged_in_as_a_school_user
    and_i_am_on_the_schools_landing_page
    when_i_start_adding_an_ect
    then_i_am_in_the_requirements_page

    when_i_click_continue
    then_i_am_on_the_find_ect_step_page

    when_i_submit_a_date_of_birth_that_does_not_match
    then_i_should_be_taken_to_the_national_insurance_number_step

    when_i_enter_a_national_insurance_number_that_does_not_match
    then_i_should_be_taken_to_the_teacher_not_found_error_page

    when_i_click_try_again
    then_i_should_be_taken_to_the_find_ect_step_page
  end

  def given_i_am_logged_in_as_a_school_user
    school = FactoryBot.create(:school)
    sign_in_as_school_user(school:)
  end

  def and_i_am_on_the_schools_landing_page
    path = "/school/home/ects"
    page.goto path
    expect(page).to have_path(path)
  end

  def when_i_start_adding_an_ect
    page.get_by_role("link", name: "Register an ECT starting at your school").click
  end

  def then_i_am_in_the_requirements_page
    expect(page).to have_path("/school/register-ect/what-you-will-need")
  end

  def when_i_click_continue
    page.get_by_role("link", name: "Continue").click
  end

  def then_i_am_on_the_find_ect_step_page
    expect(page).to have_path("/school/register-ect/find-ect")
  end

  def when_i_submit_a_date_of_birth_that_does_not_match
    page.get_by_label("trn").fill("9876543")
    page.get_by_label("day").fill("1")
    page.get_by_label("month").fill("2")
    page.get_by_label("year").fill("1980")
    page.get_by_role("button", name: "Continue").click
  end

  def then_i_should_be_taken_to_the_national_insurance_number_step
    expect(page).to have_path("/school/register-ect/national-insurance-number")
  end

  def when_i_enter_a_national_insurance_number_that_does_not_match
    page.get_by_label("National Insurance Number").fill("OA647867D")
    page.get_by_role("button", name: "Continue").click
  end

  def then_i_should_be_taken_to_the_teacher_not_found_error_page
    expect(page).to have_path("/school/register-ect/not-found")
  end

  def when_i_click_try_again
    page.get_by_role("link", name: "Try again").click
  end

  def then_i_should_be_taken_to_the_find_ect_step_page
    path = "/school/register-ect/find-ect"
    expect(page).to have_path(path)
  end
end
