describe "School user can change Mentor's email address" do
  it "changes the email address" do
    given_there_is_a_school
    and_there_is_an_ect_with_a_mentor
    and_i_am_logged_in_as_a_school_user

    when_i_visit_the_mentor_page
    then_i_can_change_the_email_address
    and_i_see_the_change_email_form

    when_i_do_not_enter_an_email_address
    and_i_continue
    error_message = "Enter an email address"
    then_i_see_an_error(message: error_message)

    when_i_do_not_enter_a_different_email_address
    and_i_continue
    error_message = "The email must be different from the current email"
    then_i_see_an_error(message: error_message)

    when_i_enter_an_invalid_email_address
    and_i_continue
    error_message = <<~TXT
      Enter an email address in the correct format, like name@example.com
    TXT
    then_i_see_an_error(message: error_message)

    when_i_enter_an_email_address_that_is_too_long
    and_i_continue
    error_message = <<~TXT
      Enter an email address that is less than 254 characters long
    TXT
    then_i_see_an_error(message: error_message)

    when_i_enter_a_valid_email_address
    and_i_continue
    then_i_am_asked_to_check_and_confirm_the_change

    when_i_confirm_the_change
    then_i_see_the_confirmation_message
  end

private

  def given_there_is_a_school
    @school = FactoryBot.create(:school)
  end

  def and_there_is_an_ect_with_a_mentor
    start_date = 3.months.ago.to_date
    @ect_teacher = FactoryBot.create(:teacher)
    @ect_period = FactoryBot.create(
      :ect_at_school_period,
      :ongoing,
      :with_training_period,
      teacher: @ect_teacher,
      school: @school,
      started_on: start_date
    )
    @mentor_teacher = FactoryBot.create(
      :teacher,
      trs_first_name: "John",
      trs_last_name: "Doe"
    )
    @mentor_period = FactoryBot.create(
      :mentor_at_school_period,
      :ongoing,
      teacher: @mentor_teacher,
      school: @school,
      started_on: start_date,
      email: "mentor@example.com"
    )
    FactoryBot.create(
      :training_period,
      :ongoing,
      :provider_led,
      :for_ect,
      ect_at_school_period: @ect_period
    )
    FactoryBot.create(
      :mentorship_period,
      :ongoing,
      mentor: @mentor_period,
      mentee: @ect_period,
      started_on: start_date
    )
  end

  def and_i_am_logged_in_as_a_school_user
    sign_in_as_school_user(school: @school)
  end

  def when_i_visit_the_mentor_page
    page.goto(schools_mentor_path(@mentor_period))
  end

  def then_i_can_change_the_email_address
    row = page.locator(".govuk-summary-list__row", hasText: "Email address")
    row.get_by_role("link", name: "Change").click
  end

  def and_i_see_the_change_email_form
    heading = page.locator("h1", hasText: "Change email address for John Doe")
    expect(heading).to be_visible
  end

  def when_i_do_not_enter_an_email_address
    page.get_by_label("Email address").fill("")
  end

  def when_i_do_not_enter_a_different_email_address
    page.get_by_label("Email address").fill(@mentor_period.email)
  end

  def when_i_enter_an_invalid_email_address
    page.get_by_label("Email address").fill("invalid_email")
  end

  def when_i_enter_an_email_address_that_is_too_long
    page.get_by_label("Email address").fill("a" * 250 + "@example.com")
  end

  def when_i_enter_a_valid_email_address
    page.get_by_label("Email address").fill("new@example.com")
  end

  def and_i_continue
    page.get_by_role("button", name: "Continue").click
  end

  def then_i_see_an_error(message:)
    error_summary = page.locator(".govuk-error-summary")
    expect(error_summary).to have_text("There is a problem")
    expect(error_summary).to have_text(message)
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
      "You have changed John Doe's email address to new@example.com"
    )
  end
end
