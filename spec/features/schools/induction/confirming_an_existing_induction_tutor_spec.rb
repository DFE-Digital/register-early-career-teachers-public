RSpec.describe "Confirming an existing induction tutor", :enable_schools_interface, :js do
  before do
    given_there_is_a_school_in_the_service
    and_i_sign_in_as_that_school_user
    # and_the_existing_details_are_not_confirmed
    then_i_am_taken_to_the_confirm_existing_induction_tutor_page
  end

  xscenario "confirming the existing details" do
    # when_i_confirm_that_the_existing_details_are_correct
    # and_i_click_confirm_and_continue
    # then_i_should_be_taken_to_the_confirmation_page
    # and_i_click_continue_to_the_school_home_page
    # then_i_should_see_the_school_home_page

    # when_i_login_again
    # then_i_should_see_the_school_home_page
  end

  xscenario "changing the existing details" do
    # when_i_change_the_induction_tutor_name_and_email
    # and_i_click_confirm_and_continue
    # then_i_should_be_taken_to_the_check_answers_page
    # when_i_confirm_the_changed_details
    # and_i_click_confirm_and_continue
    # then_i_should_be_taken_to_the_confirmation_page
    # and_i_click_continue_to_the_school_home_page
    # then_i_should_see_the_school_home_page_with_updated_induction_tutor_details

    # when_i_view_my_school_details
    # then_i_should_see_the_updated_induction_tutor_details

    # when_i_login_again
    # then_i_should_see_the_school_home_page_with_updated_induction_tutor_details
  end

  def given_there_is_a_school_in_the_service
    @school = FactoryBot.create(:school, urn: "1234567")
  end

  def and_i_sign_in_as_that_school_user
    sign_in_as_school_user(school: @school)
  end

  def then_i_am_taken_to_the_confirm_existing_induction_tutor_page
    # TODO
    page.goto("/school/confirm-existing-induction-tutor/edit")

    page.screenshot(path: "tmp/screenshot.png")

    expect(page).to have_path("/school/confirm-existing-induction-tutor/edit")
    expect(page.get_by_text("Confirm induction tutor details")).to be_visible
  end
end
