RSpec.describe "Registering an ECT - reuse previous partnership" do
  include_context "test trs api client"

  before do
    allow(Rails.application.config).to receive(:enable_schools_interface).and_return(true)
    create_contract_period_for_start_date
    create_lead_provider_and_active_lead_provider
    create_school_with_previous_choices
    create_previous_period_and_partnership
    create_appropriate_bodies
  end

  scenario "happy path - user reuses a previous partnership (provider-led)" do
    given_i_am_logged_in_as_a_state_funded_school_user
    and_i_am_on_the_schools_landing_page
    when_i_start_adding_an_ect
    then_i_am_in_the_requirements_page

    when_i_click_continue
    then_i_am_on_the_find_ect_step_page

    when_i_submit_the_find_ect_form(trn:, dob_day: "3", dob_month: "2", dob_year: "1977")
    then_i_should_be_taken_to_the_review_ect_details_page
    and_i_should_see_the_ect_details_in_the_review_page

    when_i_select_that_my_ect_name_is_incorrect
    and_i_enter_the_corrected_name
    and_i_click_confirm_and_continue
    then_i_should_be_taken_to_the_email_address_page

    when_i_enter_the_ect_email_address
    and_i_click_continue
    then_i_should_be_taken_to_the_ect_start_date_page

    when_i_enter_a_valid_start_date
    and_i_click_continue
    then_i_should_be_taken_to_the_working_pattern_page

    when_i_select_full_time
    and_i_click_continue

    handle_use_previous_choices_if_present(desired: "Yes")

    then_i_should_be_taken_to_the_check_answers_page
    and_i_should_see_previous_programme_choices_summary

    when_i_click_confirm_details
    then_i_should_be_taken_to_the_confirmation_page

    when_i_click_on_back_to_your_ects
    then_i_should_be_taken_to_the_ects_page
    and_i_should_see_the_ect_i_registered
  end

  scenario "can't reuse - pairing not active this year, must choose 'No'" do
    given_i_am_logged_in_as_a_state_funded_school_user
    and_i_am_on_the_schools_landing_page
    when_i_start_adding_an_ect
    then_i_am_in_the_requirements_page

    when_i_click_continue
    then_i_am_on_the_find_ect_step_page

    when_i_submit_the_find_ect_form(trn:, dob_day: "3", dob_month: "2", dob_year: "1977")
    then_i_should_be_taken_to_the_review_ect_details_page
    and_i_should_see_the_ect_details_in_the_review_page

    when_i_select_that_my_ect_name_is_incorrect
    and_i_enter_the_corrected_name
    and_i_click_confirm_and_continue
    then_i_should_be_taken_to_the_email_address_page

    when_i_enter_the_ect_email_address
    and_i_click_continue
    then_i_should_be_taken_to_the_ect_start_date_page

    when_i_enter_a_valid_start_date
    and_i_click_continue
    then_i_should_be_taken_to_the_working_pattern_page

    when_i_select_full_time
    and_i_click_continue

    handle_use_previous_choices_if_present(desired: "No")

    then_i_should_be_taken_to_the_appropriate_body_page

    when_i_select_an_appropriate_body
    and_i_click_continue
    then_i_should_be_taken_to_the_training_programme_page

    when_i_select_school_led
    and_i_click_continue

    then_i_should_be_taken_to_the_check_answers_page
    and_i_should_see_core_details_without_reuse

    when_i_click_confirm_details
    then_i_should_be_taken_to_the_confirmation_page
  end

  def create_contract_period_for_start_date
    @current_contract_year  = 2024
    @previous_contract_year = 2023

    @contract_period          = FactoryBot.create(:contract_period, year: @current_contract_year)
    @previous_contract_period = FactoryBot.create(:contract_period, year: @previous_contract_year)
  end

  def create_lead_provider_and_active_lead_provider
    @orange_institute_lead_provider = FactoryBot.create(:lead_provider, name: "Orange Institute")
    @jaskolski_delivery_partner = FactoryBot.create(:delivery_partner, name: "Jaskolski College Delivery Partner 1")

    Metadata::DeliveryPartnerLeadProvider.where(
      lead_provider: @orange_institute_lead_provider,
      delivery_partner: @jaskolski_delivery_partner
    ).delete_all
    Metadata::DeliveryPartnerLeadProvider.create!(
      lead_provider: @orange_institute_lead_provider,
      delivery_partner: @jaskolski_delivery_partner,
      contract_period_years: [@previous_contract_year, @current_contract_year]
    )

    @active_lead_provider_previous_year = FactoryBot.create(
      :active_lead_provider,
      lead_provider: @orange_institute_lead_provider,
      contract_period_year: @previous_contract_year
    )
    @active_lead_provider_current_year = FactoryBot.create(
      :active_lead_provider,
      lead_provider: @orange_institute_lead_provider,
      contract_period_year: @current_contract_year
    )

    @lead_provider_delivery_partnership_previous_year = FactoryBot.create(
      :lead_provider_delivery_partnership,
      active_lead_provider: @active_lead_provider_previous_year,
      delivery_partner: @jaskolski_delivery_partner
    )
    @lead_provider_delivery_partnership_current_year = FactoryBot.create(
      :lead_provider_delivery_partnership,
      active_lead_provider: @active_lead_provider_current_year,
      delivery_partner: @jaskolski_delivery_partner
    )
  end

  def create_school_with_previous_choices
    @school = FactoryBot.create(
      :school,
      :state_funded,
      :provider_led_last_chosen,
      :teaching_school_hub_ab_last_chosen,
      last_chosen_lead_provider: @orange_institute_lead_provider
    )
  end

  def create_previous_period_and_partnership
    FactoryBot.create(
      :school_partnership,
      school: @school,
      lead_provider_delivery_partnership: @lead_provider_delivery_partnership_previous_year
    )
  end

  def create_appropriate_bodies
    FactoryBot.create(:appropriate_body, name: "Golden Leaf Teaching Hub")
    FactoryBot.create(:appropriate_body, name: "Umber Teaching Hub")
  end

  def trn
    "9876543"
  end

  def given_i_am_logged_in_as_a_state_funded_school_user
    sign_in_as_school_user(school: @school)
    @school.reload

    expect(@school.independent?).to be(false)
    expect(@school.last_chosen_training_programme).to eq("provider_led")
    expect(@school.last_chosen_appropriate_body_id).to be_present
    expect(@school.last_programme_choices?).to be(true)
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

  def when_i_select_that_my_ect_name_is_incorrect
    page.get_by_label("No, they changed their name or it's spelt wrong").check
  end

  def and_i_enter_the_corrected_name
    page.get_by_label("Enter the correct full name").fill("Kirk Van Damme")
  end

  def and_i_click_confirm_and_continue
    page.get_by_role("button", name: "Confirm and continue").click
  end

  def then_i_should_be_taken_to_the_email_address_page
    expect(page).to have_path("/school/register-ect/email-address")
  end

  def when_i_enter_the_ect_email_address
    page.get_by_label("What is Kirk Van Damme’s email address?").fill("example@example.com")
  end

  def then_i_should_be_taken_to_the_ect_start_date_page
    expect(page).to have_path("/school/register-ect/start-date")
  end

  def when_i_enter_a_valid_start_date
    @entered_start_date = @contract_period.started_on + 1.month
    page.get_by_label("day").fill(@entered_start_date.day.to_s)
    page.get_by_label("month").fill(@entered_start_date.month.to_s)
    page.get_by_label("year").fill(@entered_start_date.year.to_s)
  end

  def then_i_should_be_taken_to_the_working_pattern_page
    expect(page).to have_path("/school/register-ect/working-pattern")
  end

  def when_i_select_full_time
    page.get_by_label("Full time").check
  end

  def and_i_click_continue
    page.get_by_role("button", name: "Continue").click
  end

  def handle_use_previous_choices_if_present(desired:)
    if current_path == "/school/register-ect/use-previous-ect-choices"
      page.get_by_label(desired).check
      and_i_click_continue
    end
  end

  def current_path
    URI(page.url).path
  end

  def then_i_should_be_taken_to_the_appropriate_body_page
    expect(page).to have_path("/school/register-ect/state-school-appropriate-body")
  end

  def when_i_select_an_appropriate_body(value: @school.last_chosen_appropriate_body.name)
    page.get_by_role("combobox", name: "Enter appropriate body name")
        .first
        .select_option(value:)
  end

  def then_i_should_be_taken_to_the_training_programme_page
    expect(page).to have_path("/school/register-ect/training-programme")
  end

  def when_i_select_school_led
    page.get_by_label("School-led").check
  end

  def then_i_should_be_taken_to_the_check_answers_page
    expect(page).to have_path("/school/register-ect/check-answers")
  end

  def and_i_should_see_previous_programme_choices_summary
    expect(page.get_by_text("Provider-led")).to be_visible
    expect(page.get_by_text("Orange Institute")).to be_visible
    expect(page.get_by_text(@school.last_chosen_appropriate_body.name)).to be_visible
  end

  def and_i_should_see_core_details_without_reuse
    expect(page.get_by_text(trn)).to be_visible
    expect(page.get_by_text("Kirk Van Damme")).to be_visible
    expect(page.get_by_text("example@example.com")).to be_visible
    expect(page.get_by_text(@entered_start_date.strftime("%B %Y"))).to be_visible
  end

  def when_i_click_confirm_details
    page.get_by_role("button", name: "Confirm details").click
  end

  def then_i_should_be_taken_to_the_confirmation_page
    expect(page).to have_path("/school/register-ect/confirmation")
  end

  def when_i_click_on_back_to_your_ects
    page.get_by_role("link", name: "Back to your ECTs").click
  end

  def then_i_should_be_taken_to_the_ects_page
    expect(page).to have_path("/school/home/ects")
  end

  def and_i_should_see_the_ect_i_registered
    expect(page.get_by_role("link", name: "Kirk Van Damme")).to be_visible
  end
end
