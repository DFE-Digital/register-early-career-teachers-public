RSpec.describe "Registering a mentor that is mentoring at the new school only", :enable_schools_interface do
  include_context "test TRS API returns a teacher"
  include SchoolPartnershipHelpers

  before { freeze_time }

  scenario "mentor is starting at the new school before the reported leaving date from the old school" do
    given_there_is_a_school_in_the_service
    and_there_is_an_ect_with_no_mentor_registered_at_the_school
    and_mentor_has_existing_mentorship_at_another_school_finishing_in_future
    and_i_sign_in_as_that_school_user
    and_i_am_on_the_schools_landing_page

    when_i_click_to_assign_a_mentor_to_the_ect
    then_i_should_be_taken_to_the_requirements_page

    when_i_click_continue
    then_i_should_be_taken_to_the_find_mentor_page

    when_i_submit_the_find_mentor_form
    then_i_should_be_taken_to_the_review_mentor_details_page
    and_i_should_see_the_mentor_details_in_the_review_page

    when_i_select_that_my_mentor_name_is_correct
    and_i_click_confirm_and_continue
    then_i_should_be_taken_to_the_email_address_page

    when_i_enter_the_mentor_email_address
    and_i_click_continue
    then_i_should_be_taken_to_mentoring_at_your_school_only_page

    when_i_select_yes_they_will_not_be_mentoring_at_another_school
    and_i_click_continue
    then_i_should_be_taken_to_the_start_date_page

    when_i_enter_a_start_date_before_the_previous_reported_leaving_date
    and_i_click_continue
    then_i_should_be_taken_to_the_check_answers_page
    and_i_should_see_all_the_mentor_data_on_the_page

    when_i_click_confirm_details
    then_i_should_be_taken_to_the_confirmation_page
    and_mentor_has_mentorship_with_new_school
    and_all_the_dates_are_correct
  end

private

  def given_there_is_a_school_in_the_service
    @school = FactoryBot.create(:school)
  end

  def and_the_school_is_in_a_partnership_with_a_lead_provider
    @contract_period = FactoryBot.create(
      :contract_period,
      :current,
      :with_schedules
    )
    @school_partnership = make_partnership_for(@school, @contract_period)
    @lead_provider = @school_partnership
      .lead_provider_delivery_partnership
      .lead_provider
  end

  def and_there_is_an_ect_with_no_mentor_registered_at_the_school
    @ect = FactoryBot.create(:ect_at_school_period, :ongoing, school: @school)
    @training_period = FactoryBot.create(
      :training_period,
      :ongoing,
      :school_led,
      ect_at_school_period: @ect
    )
    @ect_name = Teachers::Name.new(@ect.teacher).full_name
  end

  def and_mentor_has_existing_mentorship_at_another_school_finishing_in_future
    another_school = FactoryBot.create(:school)
    @mentor = FactoryBot.create(
      :teacher,
      trs_first_name: "Kirk",
      trs_last_name: "Van Houten",
      corrected_name: nil
    )
    @mentor_name = Teachers::Name.new(@mentor).full_name
    @existing_mentor_at_school_period = FactoryBot.create(
      :mentor_at_school_period,
      school: another_school,
      teacher: @mentor,
      started_on: 1.year.ago,
      finished_on: 2.weeks.from_now
    )
    other_ect = FactoryBot.create(
      :ect_at_school_period,
      :ongoing,
      school: another_school
    )
    @existing_mentorship = FactoryBot.create(
      :mentorship_period,
      mentee: other_ect,
      mentor: @existing_mentor_at_school_period,
      started_on: 6.months.ago,
      finished_on: 2.weeks.from_now
    )
  end

  def and_i_sign_in_as_that_school_user
    sign_in_as_school_user(school: @school)
  end

  def and_i_am_on_the_schools_landing_page
    path = "/school/home/ects"
    page.goto path
    expect(page).to have_path(path)
  end

  def when_i_click_to_assign_a_mentor_to_the_ect
    page.get_by_role("link", name: "Assign a mentor for this ECT").click
  end

  def then_i_should_be_taken_to_the_requirements_page
    expect(page.get_by_text("What you'll need to add a new mentor for #{@ect_name}")).to be_visible
    expect(page.url).to end_with("/school/register-mentor/what-you-will-need?ect_id=#{@ect.id}")
  end

  def when_i_click_continue
    page.get_by_role("link", name: "Continue").click
  end

  def then_i_should_be_taken_to_the_find_mentor_page
    path = "/school/register-mentor/find-mentor"
    expect(page).to have_path(path)
  end

  def when_i_submit_the_find_mentor_form
    page.get_by_label("trn").fill(@mentor.trn)
    page.get_by_label("day").fill("3")
    page.get_by_label("month").fill("2")
    page.get_by_label("year").fill("1977")
    page.get_by_role("button", name: "Continue").click
  end

  def then_i_should_be_taken_to_the_review_mentor_details_page
    expect(page).to have_path("/school/register-mentor/review-mentor-details")
  end

  def and_i_should_see_the_mentor_details_in_the_review_page
    expect(page.get_by_text(@mentor.trn)).to be_visible
    expect(page.get_by_text(@mentor_name)).to be_visible
    expect(page.get_by_text("3 February 1977")).to be_visible
  end

  def when_i_select_that_my_mentor_name_is_correct
    change_name_fieldset = page.locator(
      "fieldset",
      hasText: "Are these details correct for the mentor?"
    )
    change_name_fieldset.get_by_label("Yes").check
  end

  def and_i_click_confirm_and_continue
    page.get_by_role("button", name: "Confirm and continue").click
  end

  def then_i_should_be_taken_to_the_email_address_page
    expect(page).to have_path("/school/register-mentor/email-address")
  end

  def when_i_enter_the_mentor_email_address
    page.get_by_label("email").fill("example@example.com")
  end

  def and_i_click_continue
    page.get_by_role("button", name: "Continue").click
  end

  def then_i_should_be_taken_to_mentoring_at_your_school_only_page
    expect(page).to have_path("/school/register-mentor/mentoring-at-new-school-only")
  end

  def when_i_select_yes_they_will_not_be_mentoring_at_another_school
    mentoring_schools_fieldset = page.locator(
      "fieldset",
      hasText: "Will #{@mentor_name} be mentoring ECTs at your school only?"
    )
    mentoring_schools_fieldset.get_by_label("Yes").check
  end

  def then_i_should_be_taken_to_the_start_date_page
    expect(page).to have_path("/school/register-mentor/started-on")
  end

  def when_i_enter_a_start_date_before_the_previous_reported_leaving_date
    start_date_fieldset = page.locator("fieldset", hasText: "Mentor start date")
    reported_leaving_date = @existing_mentor_at_school_period.finished_on
    @new_mentor_start_date = (reported_leaving_date - 1.month).to_date
    start_date_fieldset.get_by_label("Day").fill(@new_mentor_start_date.day.to_s)
    start_date_fieldset.get_by_label("Month").fill(@new_mentor_start_date.month.to_s)
    start_date_fieldset.get_by_label("Year").fill(@new_mentor_start_date.year.to_s)
  end

  def then_i_should_be_taken_to_the_check_answers_page
    expect(page).to have_path("/school/register-mentor/check-answers")
  end

  def and_i_should_see_all_the_mentor_data_on_the_page
    expect(page.locator("dt", hasText: "Teacher reference number (TRN)")).to be_visible
    expect(page.locator("dd", hasText: @mentor.trn)).to be_visible
    expect(page.locator("dt", hasText: "Name")).to be_visible
    expect(page.locator("dd", hasText: @mentor_name)).to be_visible
    expect(page.locator("dt", hasText: "Email address")).to be_visible
    expect(page.locator("dd", hasText: "example@example.com")).to be_visible
    expect(page.locator("dt", hasText: "Mentoring only at your school")).to be_visible
    expect(page.locator("dd", hasText: "Yes")).to be_visible
  end

  def when_i_click_confirm_details
    page.get_by_role("button", name: "Confirm details").click
  end

  def then_i_should_be_taken_to_the_confirmation_page
    expect(page).to have_path("/school/register-mentor/confirmation")
  end

  def and_mentor_has_mentorship_with_new_school
    expect(@mentor.mentor_at_school_periods.size).to eq 2
    @new_mentor_at_school_period = @mentor
      .mentor_at_school_periods
      .excluding(@existing_mentor_at_school_period)
      .take
    expect(@new_mentor_at_school_period).to be_present
    expect(@new_mentor_at_school_period.mentorship_periods.size).to eq 1
    @new_mentorship = @new_mentor_at_school_period.mentorship_periods.take
    expect(@new_mentorship).to be_present
    expect(@new_mentor_at_school_period.school).to eq @school
  end

  def and_all_the_dates_are_correct
    expect(@existing_mentor_at_school_period.reload.finished_on).to eq @new_mentor_start_date
    expect(@existing_mentorship.reload.finished_on).to eq @new_mentor_start_date
    expect(@new_mentor_at_school_period.started_on).to eq @new_mentor_start_date
    expect(@new_mentorship.started_on).to eq @new_mentor_start_date
  end
end
