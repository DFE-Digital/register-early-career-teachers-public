describe "School user can change ECT's appropriate body" do
  include_context "safe_schedules"

  context "when signed in from a state school" do
    it "changes the appropriate body" do
      given_there_is_a_state_school
      and_there_are_appropriate_bodies
      and_there_is_an_ect
      and_i_am_logged_in_as_a_school_user

      when_i_visit_the_ect_page
      then_i_can_change_the_appropriate_body
      and_i_see_the_change_appropriate_body_form
      and_the_current_appropriate_body_is_not_available
      and_i_cannot_select_a_national_appropriate_body

      when_i_enter_a_blank_appropriate_body_name
      and_i_continue
      then_i_see_an_error

      when_i_select_an_appropriate_body("Wrong Appropriate Body")
      and_i_continue
      then_i_am_asked_to_check_and_confirm_the_change
      and_see_the_appropriate_body_i_selected("Wrong Appropriate Body")

      when_i_navigate_back_to_the_form
      and_i_see_the_change_appropriate_body_form

      when_i_select_an_appropriate_body("New Appropriate Body")
      and_i_continue
      then_i_am_asked_to_check_and_confirm_the_change
      and_see_the_appropriate_body_i_selected("New Appropriate Body")
      and_i_confirm_the_change
      then_i_see_the_confirmation_message

      when_i_go_back_to_the_ect_page
      then_i_see_the_new_appropriate_body_is_assigned
    end
  end

  context "when signed in from an independent school" do
    it "changes the appropriate body" do
      given_there_is_an_independent_school
      and_there_are_appropriate_bodies
      and_there_is_an_ect
      and_i_am_logged_in_as_a_school_user

      when_i_visit_the_ect_page
      then_i_can_change_the_appropriate_body
      and_i_see_the_change_appropriate_body_form
      and_the_current_appropriate_body_is_not_available
      and_i_can_select_a_national_appropriate_body

      when_i_select_a_national_appropriate_body
      and_i_continue
      then_i_am_asked_to_check_and_confirm_the_change
      and_see_the_appropriate_body_i_selected("Independent Schools Teacher Induction Panel (ISTIP)")

      when_i_navigate_back_to_the_form
      and_i_see_the_change_appropriate_body_form

      when_i_select_a_different_appropriate_body
      and_i_enter_a_blank_appropriate_body_name
      and_i_continue
      then_i_see_an_error

      when_i_select_a_different_appropriate_body
      and_i_select_an_appropriate_body("Wrong Appropriate Body")
      and_i_continue
      then_i_am_asked_to_check_and_confirm_the_change
      and_see_the_appropriate_body_i_selected("Wrong Appropriate Body")

      when_i_navigate_back_to_the_form
      and_i_see_the_change_appropriate_body_form

      when_i_select_a_different_appropriate_body
      and_i_select_an_appropriate_body("New Appropriate Body")
      and_i_continue
      then_i_am_asked_to_check_and_confirm_the_change
      and_see_the_appropriate_body_i_selected("New Appropriate Body")
      and_i_confirm_the_change
      then_i_see_the_confirmation_message

      when_i_go_back_to_the_ect_page
      then_i_see_the_new_appropriate_body_is_assigned
    end
  end

  def given_there_is_a_state_school
    @school = FactoryBot.create(:school, :state_funded)
  end

  def given_there_is_an_independent_school
    @school = FactoryBot.create(:school, :independent)
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
      email: "ect@example.com",
      school_reported_appropriate_body: @current_ab
    )
  end

  def and_there_are_appropriate_bodies
    FactoryBot.create(:appropriate_body_period, name: "New Appropriate Body")
    FactoryBot.create(:appropriate_body_period, name: "Wrong Appropriate Body")
    FactoryBot.create(:appropriate_body_period, :istip)
    @current_ab = FactoryBot.create(:appropriate_body_period, name: "Current Appropriate Body")
  end

  def and_i_am_logged_in_as_a_school_user
    sign_in_as_school_user(school: @school)
  end

  def when_i_visit_the_ect_page
    page.goto(schools_ect_path(@ect))
  end

  def then_i_can_change_the_appropriate_body
    row = page.locator(".govuk-summary-list__row", hasText: "Appropriate Body")
    row.get_by_role("link", name: "Change").click
  end

  def and_i_see_the_change_appropriate_body_form
    heading = page.locator("h1")
    expect(heading).to have_text("Select a new appropriate body for John Doe")
  end

  def when_i_select_an_appropriate_body(name)
    page.get_by_role("combobox", name: "Enter appropriate body name")
      .first
      .select_option(value: name)
  end

  def when_i_enter_a_blank_appropriate_body_name
    when_i_select_an_appropriate_body("")
  end

  def and_the_current_appropriate_body_is_not_available
    combobox = page
      .get_by_role("combobox", name: "Enter appropriate body name")
      .first

    expect(combobox).not_to have_selector(
      "option",
      text: "Current Appropriate Body",
      exact_text: true
    )
  end

  def then_i_see_an_error
    error_summary = page.locator(".govuk-error-summary")
    expect(error_summary).to have_text(
      "Select the appropriate body which will be supporting the ECT's induction"
    )
  end

  def and_i_continue
    page.get_by_role("button", name: "Continue").click
  end

  def and_see_the_appropriate_body_i_selected(name)
    ab_locator = page.locator(".govuk-summary-list__key", hasText: "New appropriate body")
    row = page.locator(".govuk-summary-list__row", has: ab_locator)

    expect(row.locator(".govuk-summary-list__value")).to have_text(name)
  end

  def then_i_am_asked_to_check_and_confirm_the_change
    heading = page.locator("h1")
    expect(heading).to have_text("Check and confirm change")
  end

  def when_i_navigate_back_to_the_form
    page.get_by_role("link", name: "Back", exact: true).click
  end

  def and_i_confirm_the_change
    page.get_by_role("button", name: "Confirm change").click
  end

  def then_i_see_the_confirmation_message
    success_panel = page.locator(".govuk-panel")
    expect(success_panel).to have_text(
      "You’ve chosen New Appropriate Body as the new appropriate body for John Doe"
    )
  end

  def when_i_go_back_to_the_ect_page
    page.get_by_role("link", name: "Back to John Doe’s details").click
  end

  def then_i_see_the_new_appropriate_body_is_assigned
    ab_locator = page.locator(".govuk-summary-list__key", hasText: "Appropriate body")
    row = page.locator(".govuk-summary-list__row", has: ab_locator)

    expect(row.locator(".govuk-summary-list__value")).to have_text("New Appropriate Body")
  end

  def and_i_cannot_select_a_national_appropriate_body
    expect(national_body_button).to have_count(0)
  end

  def and_i_can_select_a_national_appropriate_body
    expect(national_body_button).to have_count(1)
  end

  def when_i_select_a_national_appropriate_body
    national_body_button.click
  end

  def when_i_select_a_different_appropriate_body
    page.get_by_role(
      "radio",
      name: "A different appropriate body (teaching school hub)"
    ).check
  end

  def national_body_button
    page.get_by_role(
      "radio",
      name: "Independent Schools Teacher Induction Panel (ISTIP)"
    )
  end

  alias_method :and_i_select_an_appropriate_body, :when_i_select_an_appropriate_body
  alias_method :and_i_enter_a_blank_appropriate_body_name, :when_i_enter_a_blank_appropriate_body_name
end
