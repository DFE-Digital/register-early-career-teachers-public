RSpec.describe "Moving School - backdated start spec", :enable_schools_interface do
  include_context "test TRS API returns a teacher"

  before do
    create_contract_period_for_start_date
    create_lead_provider_and_active_lead_provider
    create_appropriate_bodies
  end

  around do |example|
    travel_to Date.new(2025, 6, 16) do
      example.run
    end
  end

  context "Registering a teacher at two schools" do
    context "happy path" do
      scenario "the training periods have the dates entered by the schools" do
        given_there_are_two_schools
        and_there_are_partnerships_at_the_schools
        and_the_two_schools_want_to_register_the_same_teacher_on_different_dates_which_are_not_backdated

        given_a_school_has_registered_a_teacher
        and_another_school_has_registered_the_same_teacher_at_a_later_date

        then_the_training_period_for_the_first_school_should_start_on_the_date_entered_by_the_school
        and_the_training_period_for_the_second_school_should_start_on_the_date_entered_by_the_school

        and_the_training_period_for_the_first_school_should_finish_on_the_day_training_starts_at_the_second_school
        and_the_training_period_for_the_second_school_should_be_ongoing
      end
    end

    context "when the first period has a back-dated start date" do
      scenario "the training period at the first school is aligned to the current contract period" do
        given_there_are_two_schools
        and_there_are_partnerships_at_the_schools
        and_the_two_schools_want_to_register_the_same_teacher_on_different_dates_of_which_the_earliest_is_backdated

        given_a_school_has_registered_a_teacher
        and_another_school_has_registered_the_same_teacher_at_a_later_date

        then_the_training_period_for_the_first_school_should_start_on_the_first_day_of_the_current_contract_period
        and_the_training_period_for_the_second_school_should_start_on_the_date_entered_by_the_school

        and_the_training_period_for_the_first_school_should_finish_on_the_day_training_starts_at_the_second_school
        and_the_training_period_for_the_second_school_should_be_ongoing
      end
    end

    context "when both periods have back-dated start dates" do
      scenario "the training period at the first school which has not started is deleted" do
        given_there_are_two_schools
        and_there_are_partnerships_at_the_schools
        and_the_two_schools_want_to_register_the_same_teacher_on_different_dates_of_which_are_both_backdated

        given_a_school_has_registered_a_teacher
        and_another_school_has_registered_the_same_teacher_at_a_later_date

        then_the_training_period_at_the_first_school_which_has_not_started_yet_should_be_deleted
        and_the_training_period_for_the_second_school_should_be_ongoing
      end
    end
  end

  def given_a_school_has_registered_a_teacher
    register_ect(school: @school_one, start_date: @school_one_start_date, previously_registered: false)
  end

  def and_another_school_has_registered_the_same_teacher_at_a_later_date
    register_ect(school: @school_two, start_date: @school_two_start_date, previously_registered: true)
  end

  def register_ect(school:, start_date:, previously_registered:)
    given_i_am_logged_in_as(school)

    and_i_am_on_the_schools_landing_page
    when_i_start_adding_an_ect
    then_i_am_in_the_requirements_page

    when_i_click_continue
    then_i_am_on_the_find_ect_step_page
    when_i_submit_the_find_ect_form(trn:, dob_day: "3", dob_month: "2", dob_year: "1977")
    then_i_should_be_taken_to_the_review_ect_details_page
    and_i_should_see_the_ect_details_in_the_review_page

    when_i_select_that_the_details_are_correct
    if previously_registered
      then_i_should_be_taken_to_the_registered_before_page
      and_i_click_continue
    end
    then_i_should_be_taken_to_the_email_address_page

    when_i_enter_the_ect_email_address
    and_i_click_continue
    then_i_should_be_taken_to_the_ect_start_date_page

    when_i_enter_a_valid_start_date(start_date)
    and_i_click_continue
    then_i_should_i_should_be_taken_to_the_working_pattern_page

    when_i_select_full_time
    and_i_click_continue
    then_i_should_be_taken_to_the_use_previous_ect_choices_page

    when_i_choose_to_reuse_previous_choices
    and_i_click_continue
    then_i_should_be_taken_to_the_check_answers_page
    and_i_should_see_all_the_ect_data_on_the_page(start_date)

    when_i_click_confirm_details
    then_i_should_be_taken_to_the_confirmation_page
  end

  def and_the_two_schools_want_to_register_the_same_teacher_on_different_dates_which_are_not_backdated
    @school_one_start_date = Date.new(2025, 6, 1)
    @school_two_start_date = Date.new(2025, 6, 3)
  end

  def and_the_two_schools_want_to_register_the_same_teacher_on_different_dates_of_which_the_earliest_is_backdated
    @school_one_start_date = Date.new(2025, 4, 1)
    @school_two_start_date = Date.new(2025, 6, 2)
  end

  def and_the_two_schools_want_to_register_the_same_teacher_on_different_dates_of_which_are_both_backdated
    @school_one_start_date = Date.new(2025, 4, 1)
    @school_two_start_date = Date.new(2025, 5, 1)
  end

  def then_the_training_period_for_the_first_school_should_start_on_the_date_entered_by_the_school
    ect_at_school_period_one = ECTAtSchoolPeriod.first
    expect(ect_at_school_period_one.training_periods.first.started_on).to eq(@school_one_start_date)
  end

  def and_the_training_period_for_the_second_school_should_start_on_the_date_entered_by_the_school
    ect_at_school_period_two = ECTAtSchoolPeriod.last
    expect(ect_at_school_period_two.training_periods.first.started_on).to eq(@school_two_start_date)
  end

  def and_the_training_period_for_the_first_school_should_finish_on_the_day_training_starts_at_the_second_school
    ect_at_school_period = ECTAtSchoolPeriod.first

    training_period = ect_at_school_period.training_periods.first

    expect(training_period.finished_on).to eq(@school_two_start_date)
  end

  def then_the_training_period_at_the_first_school_which_has_not_started_yet_should_be_deleted
    ect_at_school_period = ECTAtSchoolPeriod.first

    expect(ect_at_school_period.training_periods.count).to eq(0)
  end

  def and_the_training_period_for_the_second_school_should_be_ongoing
    ect_at_school_period = ECTAtSchoolPeriod.last

    training_period = ect_at_school_period.training_periods.first

    expect(training_period.finished_on).to be_nil
  end

  def then_the_training_period_for_the_first_school_should_start_on_the_first_day_of_the_current_contract_period
    ect_at_school_period = ECTAtSchoolPeriod.first

    training_period = ect_at_school_period.training_periods.first

    expect(training_period.started_on).to eq(Date.new(2025, 6, 1))
  end

  def given_i_am_logged_in_as(school)
    sign_in_as_school_user(school:)
  end

  def when_i_click_sign_out
    page.get_by_role("button", name: "Sign out").click
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

  def when_i_submit_the_find_ect_form(trn:, dob_day:, dob_month:, dob_year:)
    page.get_by_label("trn").fill(trn)
    page.get_by_label("day").fill(dob_day)
    page.get_by_label("month").fill(dob_month)
    page.get_by_label("year").fill(dob_year)
    page.get_by_role("button", name: "Continue").click
  end

  def then_i_should_be_taken_to_the_review_ect_details_page
    expect(page).to have_path("/school/register-ect/review-ect-details")
  end

  def and_i_should_see_the_ect_details_in_the_review_page
    expect(page.get_by_text(trn)).to be_visible
    expect(page.get_by_text("Kirk Van Houten")).to be_visible
    expect(page.get_by_text("3 February 1977")).to be_visible
  end

  def when_i_select_that_the_details_are_correct
    page.get_by_label("Yes").check
    page.get_by_role("button", name: "Confirm and continue").click
  end

  def then_i_should_be_taken_to_the_email_address_page
    expect(page).to have_path("/school/register-ect/email-address")
  end

  def when_i_enter_the_ect_email_address
    page.get_by_label("What is Kirk Van Houten’s email address?").fill("example@example.com")
  end

  def then_i_should_be_taken_to_the_training_programme_page
    expect(page).to have_path("/school/register-ect/training-programme")
  end

  def when_i_select_provider_led
    page.get_by_label("Provider-led").check
  end

  def when_i_select_full_time
    page.get_by_label("Full time").check
  end

  def and_i_click_continue
    page.get_by_role("button", name: "Continue").click
  end

  def then_i_should_be_taken_to_the_ect_start_date_page
    expect(page).to have_path("/school/register-ect/start-date")
  end

  def when_i_enter_a_valid_start_date(start_date)
    page.get_by_label("day").fill(start_date.day.to_s)
    page.get_by_label("month").fill(start_date.month.to_s)
    page.get_by_label("year").fill(start_date.year.to_s)
  end

  def then_i_should_be_taken_to_the_use_previous_ect_choices_page
    expect(page).to have_path("/school/register-ect/use-previous-ect-choices")
  end

  def when_i_choose_to_reuse_previous_choices
    page.get_by_label("Yes").check
  end

  def then_i_should_i_should_be_taken_to_the_working_pattern_page
    expect(page).to have_path("/school/register-ect/working-pattern")
  end

  def then_i_should_be_taken_to_the_check_answers_page
    expect(page).to have_path("/school/register-ect/check-answers")
  end

  def and_i_should_see_all_the_ect_data_on_the_page(start_date)
    expect(page.get_by_text(trn)).to be_visible
    expect(page.get_by_text("Kirk Van Houten")).to be_visible
    expect(page.get_by_text("example@example.com")).to be_visible
    expect(page.get_by_text(start_date.strftime("%B %Y"))).to be_visible
  end

  def when_i_click_confirm_details
    page.get_by_role("button", name: "Confirm details").click
  end

  def then_i_should_be_taken_to_the_confirmation_page
    page.screenshot(path: "tmp/screenshot.png")
    expect(page).to have_path("/school/register-ect/confirmation")
  end

  def then_i_should_be_taken_to_the_registered_before_page
    expect(page).to have_path("/school/register-ect/registered-before")
  end

  def given_there_are_two_schools
    @school_one = FactoryBot.create(
      :school,
      :state_funded,
      :provider_led_last_chosen,
      :teaching_school_hub_ab_last_chosen,
      last_chosen_lead_provider: @orange_institute_lead_provider
    )

    @school_two = FactoryBot.create(
      :school,
      :state_funded,
      :provider_led_last_chosen,
      :teaching_school_hub_ab_last_chosen,
      last_chosen_lead_provider: @orange_institute_lead_provider
    )
  end

  def create_lead_provider_and_active_lead_provider
    @orange_institute_lead_provider = FactoryBot.create(:lead_provider, name: "Orange Institute")
    @reuse_delivery_partner = FactoryBot.create(:delivery_partner, name: "DP for Reuse")

    @alp_current_year = FactoryBot.create(
      :active_lead_provider,
      lead_provider: @orange_institute_lead_provider,
      contract_period_year: @current_contract_year
    )

    @alp_previous_year = FactoryBot.create(
      :active_lead_provider,
      lead_provider: @orange_institute_lead_provider,
      contract_period_year: @previous_contract_year
    )

    @lpdp_current_year = FactoryBot.create(
      :lead_provider_delivery_partnership,
      active_lead_provider: @alp_current_year,
      delivery_partner: @reuse_delivery_partner
    )

    @lpdp_previous_year = FactoryBot.create(
      :lead_provider_delivery_partnership,
      active_lead_provider: @alp_previous_year,
      delivery_partner: @reuse_delivery_partner
    )
  end

  def create_contract_period_for_start_date
    @current_contract_year  = 2025
    @previous_contract_year = @current_contract_year - 1

    @contract_period_current  = FactoryBot.create(:contract_period, :with_schedules, year: @current_contract_year)
    @previous_contract_period = FactoryBot.create(:contract_period, :with_schedules, year: @previous_contract_year)
  end

  def create_appropriate_bodies
    FactoryBot.create(:appropriate_body, name: "Golden Leaf Teaching Hub")
    FactoryBot.create(:appropriate_body, name: "Umber Teaching Hub")
  end

  def and_there_are_partnerships_at_the_schools
    create_partnership(@school_one, @lpdp_previous_year)
    create_partnership(@school_two, @lpdp_previous_year)
    create_partnership(@school_one, @lpdp_current_year)
    create_partnership(@school_two, @lpdp_current_year)
  end

  def create_partnership(school, lead_provider_delivery_partnership)
    FactoryBot.create(
      :school_partnership,
      school:,
      lead_provider_delivery_partnership:
    )
  end

  def trn
    "9876543"
  end
end
