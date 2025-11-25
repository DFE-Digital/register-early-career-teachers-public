RSpec.describe "Registering an ECT - reuse previous partnership", :enable_schools_interface do
  include_context "test trs api client"

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
    and_i_see_previous_programme_choices_summary

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
    then_i_am_on_the_training_programme_page

    and_i_select_school_led
    and_i_click_continue
    then_i_am_on_the_check_answers_page
    and_i_see_core_details_without_reuse

    and_i_click_confirm_details
    then_i_am_on_the_confirmation_page
  end

  def given_i_am_logged_in_as_a_state_funded_school_user_with_previous_choices
    current_year  = Time.zone.today.year
    previous_year = current_year - 1

    @contract_period_current  = FactoryBot.create(:contract_period, :with_schedules, year: current_year)
    @contract_period_previous = FactoryBot.create(:contract_period, :with_schedules, year: previous_year)

    @lead_provider    = FactoryBot.create(:lead_provider, name: "Orange Institute")
    @delivery_partner = FactoryBot.create(:delivery_partner, name: "Jaskolski College Delivery Partner 1")

    alp_prev = FactoryBot.create(
      :active_lead_provider,
      lead_provider: @lead_provider,
      contract_period_year: previous_year
    )
    alp_curr = FactoryBot.create(
      :active_lead_provider,
      lead_provider: @lead_provider,
      contract_period_year: current_year
    )

    @lpdp_prev = FactoryBot.create(
      :lead_provider_delivery_partnership,
      active_lead_provider: alp_prev,
      delivery_partner: @delivery_partner
    )

    @lpdp_curr = LeadProviderDeliveryPartnership.find_or_create_by!(
      active_lead_provider: alp_curr,
      delivery_partner: @delivery_partner
    )

    @school = FactoryBot.create(
      :school,
      :state_funded,
      :provider_led_last_chosen,
      :teaching_school_hub_ab_last_chosen,
      last_chosen_lead_provider: @lead_provider
    )

    FactoryBot.create(
      :school_partnership,
      school: @school,
      lead_provider_delivery_partnership: @lpdp_prev
    )

    @ab_name = "Golden Leaf Teaching Hub"
    FactoryBot.create(:appropriate_body, name: @ab_name)
    FactoryBot.create(:appropriate_body, name: "Umber Teaching Hub")

    sign_in_as_school_user(school: @school)
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
    @entered_start_date = @contract_period_current.started_on + 1.month
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
    page.get_by_role("combobox", name: "Enter appropriate body name").first.select_option(value: @ab_name)
  end

  def then_i_am_on_the_training_programme_page
    expect(page).to have_path("/school/register-ect/training-programme")
  end

  def and_i_select_school_led
    page.get_by_label("School-led").check
  end

  def then_i_am_on_the_check_answers_page
    expect(page).to have_path("/school/register-ect/check-answers")
  end

  def and_i_see_previous_programme_choices_summary
    expect(page.get_by_text("Provider-led")).to be_visible
    expect(page.get_by_text("Orange Institute")).to be_visible
    if page.get_by_text(@ab_name).count.positive?
      expect(page.get_by_text(@ab_name)).to be_visible
    end
  end

  def and_i_see_core_details_without_reuse
    expect(page.get_by_text("9876543")).to be_visible
    expect(page.get_by_text("Kirk Van Houten")).to be_visible
    expect(page.get_by_text("example@example.com")).to be_visible
    expect(page.get_by_text(@entered_start_date.strftime("%B %Y"))).to be_visible
  end

  def and_i_click_confirm_details
    page.get_by_role("button", name: "Confirm details").click
  end

  def then_i_am_on_the_confirmation_page
    expect(page).to have_path("/school/register-ect/confirmation")
  end
end
