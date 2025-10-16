describe "School user can change ECTs working pattern", :enable_schools_interface do
  it "changes the working pattern" do
    given_there_is_a_school
    and_there_is_an_ect
    and_i_am_logged_in_as_a_school_user

    when_i_visit_the_ect_page
    then_i_can_change_the_working_pattern
    and_i_see_the_change_working_pattern_form

    when_i_change_the_working_pattern
    then_i_am_asked_to_check_and_confirm_the_change

    when_i_confirm_the_change
    then_i_see_the_confirmation_message
  end

  private

  def given_there_is_a_school
    @school = FactoryBot.create(:school)
  end

  def and_there_is_an_ect
    @teacher = FactoryBot.create(
      :teacher,
      trs_first_name: "John",
      trs_last_name: "Doe"
    )
    @ect = FactoryBot.create(
      :ect_at_school_period,
      :ongoing,
      teacher: @teacher,
      school: @school,
      working_pattern: :full_time
    )
  end

  def and_i_am_logged_in_as_a_school_user
    sign_in_as_school_user(school: @school)
  end

  def when_i_visit_the_ect_page
    page.goto(schools_ect_path(@ect))
  end

  def then_i_can_change_the_working_pattern
    row = page.locator(".govuk-summary-list__row", hasText: "Working pattern")
    row.get_by_role("link", name: "Change").click
  end

  def and_i_see_the_change_working_pattern_form
    heading = page.locator(
      "h1",
      hasText: "Change John Doe’s working pattern to part time"
    )
    expect(heading).to be_visible
  end

  def when_i_change_the_working_pattern
    page.get_by_role("button", name: "Change working pattern").click
  end

  def then_i_am_asked_to_check_and_confirm_the_change
    heading = page.locator("h1", hasText: "Check and confirm change")
    expect(heading).to be_visible
  end

  def when_i_confirm_the_change
    page.get_by_role("button", name: "Confirm change").click
  end

  def then_i_see_the_confirmation_message
    success_panel = page.locator(".govuk-panel")
    expect(success_panel).to have_text(
      "You have changed John Doe’s working pattern to part time"
    )
  end
end
