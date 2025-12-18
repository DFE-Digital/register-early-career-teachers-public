describe "School user reports an ECT leaving", :enable_schools_interface do
  around do |example|
    travel_to(Date.new(2025, 1, 1)) { example.run }
  end

  it "completes the leaving flow" do
    given_there_is_a_school
    and_there_is_an_ongoing_ect
    and_i_am_logged_in_as_a_school_user

    when_i_visit_the_ect_page
    then_i_can_start_the_ect_leaving_flow

    when_i_enter_a_future_leaving_date
    then_i_see_the_check_answers_page

    when_i_confirm_the_leaving_date
    then_i_see_the_leaving_confirmation

    when_i_return_to_the_ect_details
    then_i_see_the_leaving_message_and_no_cta
  end

private

  def given_there_is_a_school
    @school = FactoryBot.create(:school)
  end

  def and_there_is_an_ongoing_ect
    @teacher = FactoryBot.create(
      :teacher,
      corrected_name: "Batman"
    )

    @ect_at_school_period = FactoryBot.create(
      :ect_at_school_period,
      :ongoing,
      teacher: @teacher,
      school: @school,
      started_on: Date.new(2024, 9, 1)
    )
  end

  def and_i_am_logged_in_as_a_school_user
    sign_in_as_school_user(school: @school)
  end

  def when_i_visit_the_ect_page
    page.goto(schools_ect_path(@ect_at_school_period))
  end

  def then_i_can_start_the_ect_leaving_flow
    page.get_by_role("link", name: "Tell us if Batman is leaving permanently").click
    expect(page.locator("h1", hasText: "Tell us if Batman has left or is leaving your school permanently")).to be_visible
  end

  def when_i_enter_a_future_leaving_date
    leaving_on = Date.current + 1.month
    page.get_by_label("Day").fill(leaving_on.day.to_s)
    page.get_by_label("Month").fill(leaving_on.month.to_s)
    page.get_by_label("Year").fill(leaving_on.year.to_s)
    page.get_by_role("button", name: "Continue").click
  end

  def then_i_see_the_check_answers_page
    expect(page.locator("h1", hasText: "Confirm that Batman is leaving your school permanently")).to be_visible
  end

  def when_i_confirm_the_leaving_date
    page.get_by_role("button", name: "Confirm and continue").click
  end

  def then_i_see_the_leaving_confirmation
    expect(page.locator(".govuk-panel")).to have_text("Batman will be removed from your school’s ECT list after 1 February 2025")
  end

  def when_i_return_to_the_ect_details
    page.get_by_role("link", name: "Back to ECTs").click
    page.get_by_role("link", name: "Batman").click
  end

  def then_i_see_the_leaving_message_and_no_cta
    expect(page.locator("h2", hasText: "Batman is leaving your school")).to be_visible
    expect(page.get_by_role("link", name: "Tell us if Batman is leaving permanently")).not_to be_visible
  end
end
