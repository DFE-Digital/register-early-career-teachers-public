RSpec.describe "Registering an ECT - reuse previous EOI", :enable_schools_interface do
  include_context "test TRS API returns a teacher"
  include ReusablePartnershipHelpers

  around do |example|
    travel_to(Date.new(2025, 9, 1)) { example.run }
  end

  scenario "reuses previous choices when only a previous EOI exists" do
    given_i_am_logged_in_as_a_state_funded_school_user_with_previous_choices_but_only_eoi
    and_i_am_on_the_schools_ects_index_page
    and_i_start_adding_an_ect
    and_i_click_continue
    and_i_submit_the_find_ect_form
    and_i_choose_that_the_details_are_correct
    and_i_click_confirm_and_continue
    then_i_am_on_the_registered_before_page

    and_i_click_continue
    then_i_am_on_the_email_address_page

    and_i_enter_the_ect_email_address
    and_i_click_continue
    then_i_am_on_the_start_date_page

    and_i_enter_a_valid_start_date
    and_i_click_continue
    then_i_am_on_the_working_pattern_page

    and_i_select_full_time
    and_i_click_continue
    then_i_am_on_the_use_previous_choices_page

    and_i_choose_to_reuse_previous_choices
    and_i_click_continue
    then_i_am_on_the_check_answers_page
    and_i_see_previous_programme_choices_summary_when_reusing

    and_i_click_confirm_details
    then_i_am_on_the_confirmation_page
  end

  def given_i_am_logged_in_as_a_state_funded_school_user_with_previous_choices_but_only_eoi
    @teacher = Teacher.find_or_create_by!(trn: "9876543")
    @previous_school = FactoryBot.create(:school)

    @current_contract_period = FactoryBot.create(:contract_period, :with_schedules, year: 2025)
    previous_contract_period = FactoryBot.create(:contract_period, :with_schedules, year: 2024)

    @last_chosen_lead_provider = FactoryBot.create(:lead_provider, name: "Orange Institute")

    previous_year_active_lead_provider = FactoryBot.create(
      :active_lead_provider,
      lead_provider: @last_chosen_lead_provider,
      contract_period: previous_contract_period
    )

    FactoryBot.create(
      :active_lead_provider,
      lead_provider: @last_chosen_lead_provider,
      contract_period: @current_contract_period
    )

    @current_school = FactoryBot.create(
      :school,
      :state_funded,
      :provider_led_last_chosen,
      :teaching_school_hub_ab_last_chosen,
      last_chosen_lead_provider: @last_chosen_lead_provider
    )

    @appropriate_body_name = "Golden Leaf Teaching Hub"
    FactoryBot.create(:appropriate_body_period, name: @appropriate_body_name)
    FactoryBot.create(:appropriate_body_period, name: "Umber Teaching Hub")

    previous_ect_at_school_period = FactoryBot.create(
      :ect_at_school_period,
      school: @current_school,
      teacher: @teacher,
      started_on: Date.new(2024, 9, 1),
      finished_on: Date.new(2025, 6, 30)
    )

    FactoryBot.create(
      :training_period,
      ect_at_school_period: previous_ect_at_school_period,
      training_programme: "provider_led",
      expression_of_interest: previous_year_active_lead_provider,
      school_partnership: nil,
      started_on: Date.new(2024, 9, 1),
      finished_on: Date.new(2025, 6, 30)
    )

    sign_in_as_school_user(school: @current_school)
  end

  def and_i_am_on_the_schools_ects_index_page
    page.goto "/school/home/ects"
  end

  def and_i_start_adding_an_ect
    page.get_by_role("link", name: "Register an ECT starting at your school").click
  end

  def and_i_click_continue
    if page.get_by_role("link", name: "Continue").count.positive?
      page.get_by_role("link", name: "Continue").click
    else
      page.get_by_role("button", name: "Continue").click
    end
  end

  def and_i_submit_the_find_ect_form
    page.get_by_label("trn").fill("9876543")
    page.get_by_label("day").fill("3")
    page.get_by_label("month").fill("2")
    page.get_by_label("year").fill("1977")
    page.get_by_role("button", name: "Continue").click

    expect(page).to have_path("/school/register-ect/review-ect-details")
    expect(page.get_by_text("9876543")).to be_visible
    expect(page.get_by_text("Kirk Van Houten")).to be_visible
    expect(page.get_by_text("3 February 1977")).to be_visible
  end

  def and_i_choose_that_the_details_are_correct
    page.get_by_label("Yes").check
  end

  def and_i_click_confirm_and_continue
    if page.get_by_role("button", name: "Confirm and continue").count.positive?
      page.get_by_role("button", name: "Confirm and continue").click
    else
      page.get_by_role("button", name: "Continue").click
    end
  end

  def then_i_am_on_the_registered_before_page
    expect(page).to have_path("/school/register-ect/registered-before")
  end

  def then_i_am_on_the_email_address_page
    expect(page).to have_path("/school/register-ect/email-address")
  end

  def and_i_enter_the_ect_email_address
    if page.locator('input[type="email"]').count.positive?
      page.fill('input[type="email"]', "example@example.com")
    else
      page.get_by_label(/email address/i).fill("example@example.com")
    end
  end

  def then_i_am_on_the_start_date_page
    expect(page).to have_path("/school/register-ect/start-date")
  end

  def and_i_enter_a_valid_start_date
    @entered_start_date = @current_contract_period.started_on + 1.month
    page.get_by_label("day").fill(@entered_start_date.day.to_s)
    page.get_by_label("month").fill(@entered_start_date.month.to_s)
    page.get_by_label("year").fill(@entered_start_date.year.to_s)
  end

  def then_i_am_on_the_working_pattern_page
    expect(page).to have_path("/school/register-ect/working-pattern")
  end

  def and_i_select_full_time
    page.get_by_label("Full time").check
  end

  def then_i_am_on_the_use_previous_choices_page
    expect(page).to have_path("/school/register-ect/use-previous-ect-choices")
  end

  def and_i_choose_to_reuse_previous_choices
    page.get_by_label("Yes").check
  end

  def then_i_am_on_the_check_answers_page
    expect(page).to have_path("/school/register-ect/check-answers")
  end

  def and_i_see_previous_programme_choices_summary_when_reusing
    expect(page.get_by_text("Choices used by your school previously").first).to be_visible
    expect(page.get_by_text("Provider-led")).to be_visible
    expect(page.get_by_text(@last_chosen_lead_provider.name)).to be_visible
  end

  def and_i_click_confirm_details
    page.get_by_role("button", name: "Confirm details").click
  end

  def then_i_am_on_the_confirmation_page
    expect(page).to have_path("/school/register-ect/confirmation")
  end
end
