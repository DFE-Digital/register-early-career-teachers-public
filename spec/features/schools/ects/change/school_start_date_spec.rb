describe "School user can change an ECT's school start date" do
  include_context "safe_schedules"

  before { travel_to Date.new(2025, 9, 1) }

  it "changes the related period dates without changing the schedule" do
    given_there_is_a_school
    and_there_is_an_ect_with_training_and_mentorship_periods
    and_i_am_logged_in_as_a_school_user

    when_i_visit_the_ect_page
    then_i_can_change_the_school_start_date
    and_i_see_the_change_school_start_date_form

    when_i_enter_a_later_start_date
    and_i_continue
    then_i_am_asked_to_check_and_confirm_the_change

    when_i_confirm_the_change
    then_i_see_the_confirmation_message
    and_the_related_period_dates_are_changed
    and_the_training_schedule_is_unchanged
  end

private

  def given_there_is_a_school
    @school = FactoryBot.create(:school)
  end

  def and_there_is_an_ect_with_training_and_mentorship_periods
    @teacher = FactoryBot.create(
      :teacher,
      trs_first_name: "John",
      trs_last_name: "Doe"
    )

    @current_start_date = Date.current - 1.day
    @new_start_date = Date.current

    @ect = FactoryBot.create(
      :ect_at_school_period,
      :unfinished,
      teacher: @teacher,
      school: @school,
      started_on: @current_start_date
    )

    @training_period = FactoryBot.create(
      :training_period,
      :provider_led,
      :unfinished,
      :for_ect,
      ect_at_school_period: @ect,
      started_on: @current_start_date
    )

    @original_schedule = @training_period.schedule

    mentor = FactoryBot.create(
      :mentor_at_school_period,
      :unfinished,
      school: @school,
      started_on: @current_start_date - 1.month
    )

    @mentorship_period = FactoryBot.create(
      :mentorship_period,
      :unfinished,
      mentee: @ect,
      mentor:,
      started_on: @current_start_date
    )
  end

  def and_i_am_logged_in_as_a_school_user
    sign_in_as_school_user(school: @school)
  end

  def when_i_visit_the_ect_page
    page.goto(schools_ect_path(@ect))
  end

  def then_i_can_change_the_school_start_date
    row = page.locator(
      ".govuk-summary-list__row",
      hasText: "School start date"
    )

    row.get_by_role("link", name: "Change").click
  end

  def and_i_see_the_change_school_start_date_form
    heading = page.locator(
      "h1",
      hasText: "Change school start date for John Doe"
    )

    expect(heading).to be_visible
  end

  def when_i_enter_a_later_start_date
    page.get_by_label("Day").fill(@new_start_date.day.to_s)
    page.get_by_label("Month").fill(@new_start_date.month.to_s)
    page.get_by_label("Year").fill(@new_start_date.year.to_s)
  end

  def and_i_continue
    page.get_by_role("button", name: "Continue").click
  end

  def then_i_am_asked_to_check_and_confirm_the_change
    heading = page.locator(
      "h1",
      hasText: "Check and confirm change"
    )

    expect(heading).to be_visible
    expect(page.locator("body")).to have_text(
      @new_start_date.to_fs(:govuk)
    )
  end

  def when_i_confirm_the_change
    page.get_by_role("button", name: "Confirm change").click
  end

  def then_i_see_the_confirmation_message
    success_panel = page.locator(".govuk-panel")

    expect(success_panel).to have_text(
      "You’ve changed John Doe’s school start date " \
      "to #{@new_start_date.to_fs(:govuk)}"
    )
  end

  def and_the_related_period_dates_are_changed
    expect(@ect.reload.started_on)
      .to eq(@new_start_date)

    expect(@training_period.reload.started_on)
      .to eq(@new_start_date)

    expect(@mentorship_period.reload.started_on)
      .to eq(@new_start_date)
  end

  def and_the_training_schedule_is_unchanged
    expect(@training_period.reload.schedule)
      .to eq(@original_schedule)
  end
end
