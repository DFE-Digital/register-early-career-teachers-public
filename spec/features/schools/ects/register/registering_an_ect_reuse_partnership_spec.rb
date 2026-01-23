RSpec.describe "Registering an ECT - reuse previous partnership", :enable_schools_interface do
  include_context "test TRS API returns a teacher"
  include ReusablePartnershipHelpers

  around do |example|
    travel_to(Date.new(2025, 9, 1)) { example.run }
  end

  scenario "reuses a previous partnership (provider-led)" do
    given_i_am_logged_in_as_a_state_funded_school_user_with_previous_choices
    and_i_am_on_the_schools_ects_index_page
    and_i_start_adding_an_ect
    and_i_click_continue
    and_i_submit_the_find_ect_form
    and_i_choose_that_the_details_are_correct
    and_i_click_confirm_and_continue
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

  scenario "can't reuse—pairing not active this year" do
    given_i_am_logged_in_as_a_state_funded_school_user_with_previous_choices
    and_i_am_on_the_schools_ects_index_page
    and_i_start_adding_an_ect
    and_i_click_continue
    and_i_submit_the_find_ect_form
    and_i_choose_that_the_details_are_correct
    and_i_click_confirm_and_continue
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

    and_i_choose_not_to_reuse_previous_choices
    and_i_click_continue
    then_i_am_on_the_appropriate_body_page

    and_i_select_an_appropriate_body
    and_i_click_continue
    then_i_am_on_the_training_programmme_page

    and_i_select_school_led
    and_i_click_continue
    then_i_am_on_the_check_answers_page
    and_i_see_check_answers_when_not_reusing_previous_choices

    and_i_click_confirm_details
    then_i_am_on_the_confirmation_page
  end

  def given_i_am_logged_in_as_a_state_funded_school_user_with_previous_choices
    context = build_school_with_reusable_provider_led_partnership

    @current_school               = context.school
    @current_contract_period      = context.current_contract_period
    @previous_school_partnership  = context.previous_school_partnership
    @last_chosen_lead_provider    = context.last_chosen_lead_provider
    @previous_year_delivery_partner = context.previous_year_delivery_partner

    @appropriate_body_name = "Golden Leaf Teaching Hub"
    FactoryBot.create(:appropriate_body, name: @appropriate_body_name)
    FactoryBot.create(:appropriate_body, name: "Umber Teaching Hub")

    stub_reuse_finder_to_return(@previous_school_partnership)

    sign_in_as_school_user(school: @current_school)
  end

  def stub_reuse_finder_to_return(previous_partnership)
    reuse_finder = instance_double(SchoolPartnerships::FindPreviousReusable)

    allow(SchoolPartnerships::FindPreviousReusable).to receive(:new)
      .and_return(reuse_finder)

    allow(reuse_finder).to receive(:call)
      .and_return(previous_partnership)
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

  def and_i_choose_not_to_reuse_previous_choices
    page.get_by_label("No").check
  end

  def then_i_am_on_the_appropriate_body_page
    expect(page).to have_path("/school/register-ect/state-school-appropriate-body")
  end

  def and_i_select_an_appropriate_body
    page.get_by_role("combobox", name: "Enter appropriate body name")
        .first
        .select_option(value: @appropriate_body_name)
  end

  def then_i_am_on_the_training_programmme_page
    expect(page).to have_path("/school/register-ect/training-programme")
  end

  def and_i_select_school_led
    page.get_by_label("School-led").check
  end

  def then_i_am_on_the_check_answers_page
    expect(page).to have_path("/school/register-ect/check-answers")
  end

  def and_i_see_previous_programme_choices_summary_when_reusing
    expect(page.get_by_text("Choices used by your school previously").first).to be_visible
    expect(page.get_by_text("Provider-led")).to be_visible
    expect(page.get_by_text(@last_chosen_lead_provider.name)).to be_visible

    if page.get_by_text(@appropriate_body_name).count.positive?
      expect(page.get_by_text(@appropriate_body_name)).to be_visible
    end
  end

  def and_i_see_check_answers_when_not_reusing_previous_choices
    expect(page.get_by_text("Choices used by your school previously").first).to be_visible
    expect(page.get_by_text("9876543")).to be_visible
    expect(page.get_by_text("Kirk Van Houten")).to be_visible
    expect(page.get_by_text("example@example.com")).to be_visible
    expect(page.get_by_text(@entered_start_date.strftime("%B %Y"))).to be_visible
    expect(page.get_by_text("School-led")).to be_visible
    expect(page.get_by_text(@appropriate_body_name)).to be_visible
  end

  def and_i_click_confirm_details
    page.get_by_role("button", name: "Confirm details").click
  end

  def then_i_am_on_the_confirmation_page
    expect(page).to have_path("/school/register-ect/confirmation")
  end
end
