RSpec.describe "Changing an mentor's name", :enable_schools_interface do
  let!(:mentor_at_school_period) do
    FactoryBot.create(:mentor_at_school_period, :ongoing, school:, teacher:)
  end

  let(:teacher) do
    FactoryBot.create(:teacher, trs_first_name: "Miriam", trs_last_name: "Margolyes")
  end

  let(:school) { FactoryBot.create(:school) }

  before do
    given_i_am_logged_in_as_a_school_user
    and_there_are_mentors_with_ongoing_ects_assigned
    and_i_visit_the_mentors_page
    when_i_select_a_mentor
    and_i_try_to_change_the_mentor_name
    then_i_should_see_the_change_name_page
  end

  scenario "valid name" do
    when_i_change_the_name_to("Sister Mildred")
    and_i_click_the_continue_button
    then_i_should_be_taken_to_the_check_answers_page
    and_i_should_see_the_name("Sister Mildred")
    and_i_should_see_the_name("Miriam Margolyes")
    and_i_click_the_confirmation_button
    then_i_should_be_taken_to_the_confirmation_page
    then_the_teacher_name_should_be_corrected
  end

  scenario "edit before confirming" do
    when_i_change_the_name_to("Professor Sprout")
    and_i_click_the_continue_button
    then_i_should_be_taken_to_the_check_answers_page
    and_i_click_the_back_link
    then_i_should_see_the_change_name_page
    then_the_form_should_should_show("Professor Sprout")
    when_i_change_the_name_to("Sister Mildred")
    and_i_click_the_continue_button
    and_i_click_the_confirmation_button
    then_the_teacher_name_should_be_corrected
  end

  scenario "cancel and reset" do
    when_i_change_the_name_to("Professor Sprout")
    and_i_click_the_continue_button
    then_i_should_be_taken_to_the_check_answers_page
    and_i_click_the_cancel_link
    and_i_try_to_change_the_mentor_name
    then_i_should_see_the_change_name_page
    then_the_form_should_be_reset
  end

  scenario "invalid long name" do
    when_i_change_the_name_to(Faker::Lorem.characters(number: 71))
    and_i_click_the_continue_button
    expect(page.get_by_role("link", name: "Corrected name must be 70 characters or less")).to be_visible
    then_i_should_be_taken_to_the_edit_page
  end

  scenario "invalid blank name" do
    when_i_change_the_name_to("")
    and_i_click_the_continue_button
    expect(page.get_by_role("link", name: "Enter the correct full name")).to be_visible
    then_i_should_be_taken_to_the_edit_page
  end

  scenario "invalid same name" do
    when_i_change_the_name_to("Miriam Margolyes")
    and_i_click_the_continue_button
    expect(page.get_by_role("link", name: "The name must be different from the current name")).to be_visible
    then_i_should_be_taken_to_the_edit_page
  end

  def given_i_am_logged_in_as_a_school_user
    sign_in_as_school_user(school:)
  end

  def and_there_are_mentors_with_ongoing_ects_assigned
    mentee = FactoryBot.create(:ect_at_school_period, :ongoing, school: mentor_at_school_period.school)
    FactoryBot.create(:mentorship_period, mentor: mentor_at_school_period, mentee:)
  end

  def and_i_visit_the_mentors_page
    page.goto(schools_mentors_home_path)
    expect(page).to have_path("/school/home/mentors")
  end

  def when_i_select_a_mentor
    page.get_by_role("link", name: "Miriam Margolyes").click
  end

  def then_i_should_see_the_change_name_page
    expect(page.get_by_text("Change name for Miriam Margolyes")).to be_visible
  end

  def when_i_change_the_name_to(name)
    page.get_by_label("What’s the correct full name for Miriam Margolyes?").fill(name)
  end

  def and_i_try_to_change_the_mentor_name
    page.get_by_role("link", name: "Change").first.click
  end

  def and_i_click_the_continue_button
    page.get_by_role("button", name: "Continue").click
  end

  def and_i_click_the_confirmation_button
    page.get_by_role("button", name: "Confirm change").click
  end

  def and_i_click_the_back_link
    page.get_by_role("link", name: "Back", exact: true).click
  end

  def and_i_click_the_cancel_link
    page.get_by_role("link", name: "Cancel").click
  end

  def then_i_should_be_taken_to_the_edit_page
    expect(page).to have_path("/school/mentors/#{mentor_at_school_period.id}/change-name/edit")
  end

  def then_i_should_be_taken_to_the_check_answers_page
    expect(page).to have_path("/school/mentors/#{mentor_at_school_period.id}/change-name/check-answers")
  end

  def then_i_should_be_taken_to_the_confirmation_page
    expect(page).to have_path("/school/mentors/#{mentor_at_school_period.id}/change-name/confirmation")
  end

  def and_i_should_see_the_name(name)
    expect(page.get_by_text(name, exact: true)).to be_visible
  end

  def then_the_teacher_name_should_be_corrected
    expect(teacher.reload.corrected_name).to eq("Sister Mildred")
  end

  def then_the_form_should_be_reset(name = "Miriam Margolyes")
    expect(page.locator("#edit-name-field").input_value).to eq(name)
  end

  alias_method :then_the_form_should_should_show, :then_the_form_should_be_reset
end
