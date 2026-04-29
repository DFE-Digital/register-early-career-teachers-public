RSpec.describe "Registering an ECT - closed contract period" do
  include_context "test TRS API returns a teacher"

  before { travel_to Date.new(2024, 9, 1) }

  scenario "reassigns a previously registered provider-led ECT from a closed contract period to 2024 using a confirmed partnership" do
    given_i_am_logged_in_as_a_state_funded_school_user_registering_an_ect_from_a_closed_contract_period
    and_the_previous_training_period_used_a_confirmed_partnership
    and_a_current_2024_confirmed_partnership_exists
    and_i_am_on_the_schools_ects_index_page
    and_i_start_adding_an_ect
    and_i_click_continue
    and_i_submit_the_find_ect_form
    and_i_choose_that_the_details_are_correct
    and_i_click_confirm_and_continue
    then_i_am_on_the_registered_before_page
    and_i_see_the_previous_programme_choices

    when_i_click_continue
    then_i_am_on_the_email_address_page

    and_i_enter_the_ect_email_address
    and_i_click_continue
    then_i_am_on_the_start_date_page

    and_i_enter_a_valid_start_date_in_2024_contract_period
    and_i_click_continue
    then_i_am_on_the_working_pattern_page

    and_i_select_full_time
    and_i_click_continue
    then_i_am_on_the_use_previous_choices_page

    and_i_choose_to_reuse_previous_choices
    and_i_click_continue
    then_i_am_on_the_check_answers_page
    and_i_see_2024_programme_choices_summary

    and_i_click_confirm_details
    then_i_am_on_the_confirmation_page
    and_i_visit_the_school_view_for_the_registered_ect
    and_i_see_the_2024_confirmed_partnership_on_the_school_view
    and_the_new_training_period_is_created_in_2024_with_a_confirmed_partnership
    and_the_previous_training_period_contract_period_is_unchanged
  end

  scenario "reassigns a previously registered provider-led ECT from a closed contract period to 2024 using an EOI when no confirmed partnership exists" do
    given_i_am_logged_in_as_a_state_funded_school_user_registering_an_ect_from_a_closed_contract_period
    and_the_previous_training_period_used_an_eoi
    and_no_current_2024_confirmed_partnership_exists
    and_i_am_on_the_schools_ects_index_page
    and_i_start_adding_an_ect
    and_i_click_continue
    and_i_submit_the_find_ect_form
    and_i_choose_that_the_details_are_correct
    and_i_click_confirm_and_continue
    then_i_am_on_the_registered_before_page
    and_i_see_the_previous_programme_choices

    when_i_click_continue
    then_i_am_on_the_email_address_page

    and_i_enter_the_ect_email_address
    and_i_click_continue
    then_i_am_on_the_start_date_page

    and_i_enter_a_valid_start_date_in_2024_contract_period
    and_i_click_continue
    then_i_am_on_the_working_pattern_page

    and_i_select_full_time
    and_i_click_continue
    then_i_am_on_the_use_previous_choices_page

    and_i_choose_to_reuse_previous_choices
    and_i_click_continue
    then_i_am_on_the_check_answers_page
    and_i_see_2024_programme_choices_summary

    and_i_click_confirm_details
    then_i_am_on_the_confirmation_page
    and_i_visit_the_school_view_for_the_registered_ect
    and_i_see_the_2024_eoi_details_on_the_school_view
    and_the_new_training_period_is_created_in_2024_with_an_eoi
    and_the_previous_training_period_contract_period_is_unchanged
  end

  def given_i_am_logged_in_as_a_state_funded_school_user_registering_an_ect_from_a_closed_contract_period
    @teacher = Teacher.find_or_create_by!(trn: "9876543")
    @previous_school = FactoryBot.create(:school, :state_funded)
    @previous_school_name = "Previous Test School"
    FactoryBot.create(:gias_school, school: @previous_school, name: @previous_school_name)

    @closed_contract_period = FactoryBot.create(:contract_period, :with_schedules, :with_payments_frozen, year: 2022)
    @open_contract_period = FactoryBot.create(:contract_period, :with_extended_schedule, year: 2024)

    @lead_provider = FactoryBot.create(:lead_provider, name: "Orange Institute")
    @delivery_partner = FactoryBot.create(:delivery_partner, name: "Jaskolski College Delivery Partner 1")

    @current_school = FactoryBot.create(
      :school,
      :state_funded,
      :provider_led_last_chosen,
      :teaching_school_hub_ab_last_chosen,
      last_chosen_lead_provider: @lead_provider
    )

    @closed_active_lead_provider = FactoryBot.create(
      :active_lead_provider,
      lead_provider: @lead_provider,
      contract_period: @closed_contract_period
    )

    @open_active_lead_provider = FactoryBot.create(
      :active_lead_provider,
      lead_provider: @lead_provider,
      contract_period: @open_contract_period
    )

    @previous_ect_at_school_period = FactoryBot.create(
      :ect_at_school_period,
      school: @previous_school,
      teacher: @teacher,
      started_on: Date.new(2022, 9, 1),
      finished_on: Date.new(2023, 7, 31)
    )

    @appropriate_body_name = "Golden Leaf Teaching Hub"
    FactoryBot.create(:appropriate_body_period, name: @appropriate_body_name)
    FactoryBot.create(:appropriate_body_period, name: "Umber Teaching Hub")

    sign_in_as_school_user(school: @current_school)
  end

  def and_the_previous_training_period_used_a_confirmed_partnership
    @previous_training_period = FactoryBot.create(
      :training_period,
      :with_active_lead_provider,
      ect_at_school_period: @previous_ect_at_school_period,
      training_programme: "provider_led",
      started_on: Date.new(2022, 9, 1),
      finished_on: Date.new(2023, 7, 31),
      active_lead_provider: @closed_active_lead_provider
    )
  end

  def and_the_previous_training_period_used_an_eoi
    @previous_training_period = FactoryBot.create(
      :training_period,
      ect_at_school_period: @previous_ect_at_school_period,
      training_programme: "provider_led",
      started_on: Date.new(2022, 9, 1),
      finished_on: Date.new(2023, 7, 31),
      expression_of_interest: @closed_active_lead_provider,
      school_partnership: nil
    )
  end

  def and_a_current_2024_confirmed_partnership_exists
    @open_delivery_partnership = FactoryBot.create(
      :lead_provider_delivery_partnership,
      active_lead_provider: @open_active_lead_provider,
      delivery_partner: @delivery_partner
    )

    @current_school_partnership = FactoryBot.create(
      :school_partnership,
      school: @current_school,
      lead_provider_delivery_partnership: @open_delivery_partnership
    )
  end

  def and_no_current_2024_confirmed_partnership_exists
    @open_delivery_partnership = FactoryBot.create(
      :lead_provider_delivery_partnership,
      active_lead_provider: @open_active_lead_provider,
      delivery_partner: @delivery_partner
    )
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

  alias_method :when_i_click_continue, :and_i_click_continue

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

  def and_i_see_the_previous_programme_choices
    expect(page.get_by_text(@previous_school_name)).to be_visible
    expect(page.get_by_text("Provider-led")).to be_visible
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

  def and_i_enter_a_valid_start_date_in_2024_contract_period
    @entered_start_date = @open_contract_period.started_on + 1.month
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

  def and_i_see_2024_programme_choices_summary
    expect(page.get_by_text("Choices used by your school previously").first).to be_visible
    expect(page.get_by_text("Provider-led")).to be_visible
    expect(page.get_by_text(@lead_provider.name)).to be_visible
  end

  def and_i_click_confirm_details
    page.get_by_role("button", name: "Confirm details").click
  end

  def then_i_am_on_the_confirmation_page
    expect(page).to have_path("/school/register-ect/confirmation")
  end

  def and_i_visit_the_school_view_for_the_registered_ect
    ect_at_school_period = ECTAtSchoolPeriod.where(school: @current_school, teacher: @teacher).order(:created_at).last
    page.goto("/school/ects/#{ect_at_school_period.id}")
  end

  def and_i_see_the_2024_confirmed_partnership_on_the_school_view
    expect(page.get_by_text(@lead_provider.name)).to be_visible
    expect(page.get_by_text(@delivery_partner.name)).to be_visible
  end

  def and_i_see_the_2024_eoi_details_on_the_school_view
    expect(page.get_by_text(@lead_provider.name)).to be_visible
    expect(page.get_by_text("Yet to be reported by the lead provider")).to be_visible
  end

  def and_the_new_training_period_is_created_in_2024_with_a_confirmed_partnership
    ect_at_school_period = ECTAtSchoolPeriod.where(school: @current_school, teacher: @teacher).order(:created_at).last
    expect(ect_at_school_period).to be_present

    training_period = ect_at_school_period.training_periods.order(:created_at).last
    expect(training_period).to be_present
    expect(training_period.training_programme).to eq("provider_led")
    expect(training_period.school_partnership).to eq(@current_school_partnership)
    expect(training_period.expression_of_interest).to be_nil
    expect(training_period.contract_period).to eq(@open_contract_period)
  end

  def and_the_new_training_period_is_created_in_2024_with_an_eoi
    ect_at_school_period = ECTAtSchoolPeriod.where(school: @current_school, teacher: @teacher).order(:created_at).last
    expect(ect_at_school_period).to be_present

    training_period = ect_at_school_period.training_periods.order(:created_at).last
    expect(training_period).to be_present
    expect(training_period.training_programme).to eq("provider_led")
    expect(training_period.school_partnership).to be_nil
    expect(training_period.expression_of_interest).to be_present
    expect(training_period.expression_of_interest.contract_period).to eq(@open_contract_period)
  end

  def and_the_previous_training_period_contract_period_is_unchanged
    @previous_training_period.reload

    if @previous_training_period.school_partnership.present?
      expect(@previous_training_period.school_partnership.contract_period).to eq(@closed_contract_period)
    else
      expect(@previous_training_period.expression_of_interest.contract_period).to eq(@closed_contract_period)
    end
  end
end
