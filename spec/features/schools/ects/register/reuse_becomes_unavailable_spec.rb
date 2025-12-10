RSpec.describe "Registering an ECT, reuse becomes unavailable", :enable_schools_interface do
  include_context "test trs api client"

  scenario "reuse chosen, start date changed to a year without a partnership, programme choices must be reselected" do
    given_a_school_with_reusable_choices
    and_i_sign_in_as_that_school

    when_i_register_an_ect_and_choose_to_reuse_previous_choices
    then_i_see_reused_programme_choices_on_check_answers

    when_i_change_the_start_date_to_a_year_with_no_active_partnership
    then_i_am_taken_back_through_programme_steps_and_choose_new_answers
    and_i_do_not_see_old_lead_provider_on_check_answers
  end

  def given_a_school_with_reusable_choices
    current_year = Time.zone.today.year

    @previous_contract_period = FactoryBot.create(:contract_period, :with_schedules, year: current_year - 1)
    @current_contract_period  = FactoryBot.create(:contract_period, :with_schedules, year: current_year)
    @future_contract_period   = FactoryBot.create(:contract_period, :with_schedules, year: current_year + 1)

    @lead_provider               = FactoryBot.create(:lead_provider)
    @current_delivery_partner    = FactoryBot.create(:delivery_partner, name: "Current Delivery Partner")
    @future_delivery_partner     = FactoryBot.create(:delivery_partner, name: "Future Delivery Partner")
    @appropriate_body            = FactoryBot.create(:appropriate_body, name: "Current Appropriate Body")
    @new_appropriate_body        = FactoryBot.create(:appropriate_body, name: "New Appropriate Body")

    previous_active_lp = FactoryBot.create(:active_lead_provider, lead_provider: @lead_provider, contract_period: @previous_contract_period)
    current_active_lp  = FactoryBot.create(:active_lead_provider, lead_provider: @lead_provider, contract_period: @current_contract_period)
    future_active_lp   = FactoryBot.create(:active_lead_provider, lead_provider: @lead_provider, contract_period: @future_contract_period)

    previous_delivery_partnership = FactoryBot.create(
      :lead_provider_delivery_partnership,
      active_lead_provider: previous_active_lp,
      delivery_partner: @current_delivery_partner
    )

    FactoryBot.create(
      :lead_provider_delivery_partnership,
      active_lead_provider: future_active_lp,
      delivery_partner: @future_delivery_partner
    )

    FactoryBot.create(
      :lead_provider_delivery_partnership,
      active_lead_provider: current_active_lp,
      delivery_partner: @current_delivery_partner
    )

    @school = FactoryBot.create(
      :school,
      :state_funded,
      last_chosen_training_programme: "provider_led",
      last_chosen_lead_provider: @lead_provider,
      last_chosen_appropriate_body: @appropriate_body
    )

    @previous_school_partnership = FactoryBot.create(
      :school_partnership,
      school: @school,
      lead_provider_delivery_partnership: previous_delivery_partnership
    )
  end

  def and_i_sign_in_as_that_school
    sign_in_as_school_user(school: @school)
  end

  def when_i_register_an_ect_and_choose_to_reuse_previous_choices
    page.goto "/school/home/ects"
    page.get_by_role("link", name: "Register an ECT starting at your school").click

    click_continue
    fill_in_trn_and_dob
    click_continue

    page.get_by_label("Yes").check
    click_confirm_and_continue

    page.fill('input[type="email"]', "example@example.com")
    click_continue

    enter_start_date(@current_contract_period.started_on + 1.month)
    click_continue

    page.get_by_label("Full time").check
    click_continue

    page.get_by_label("Yes").check
    click_continue
  end

  def then_i_see_reused_programme_choices_on_check_answers
    expect(page).to have_path("/school/register-ect/check-answers")
    expect(page.get_by_text(@lead_provider.name).first).to be_visible
    expect(page.get_by_text("Choices used by your school previously").first).to be_visible
  end

  def when_i_change_the_start_date_to_a_year_with_no_active_partnership
    page.get_by_role("link", name: "Change school start date").click
    enter_start_date(@future_contract_period.started_on + 1.month)
    click_continue
  end

  def then_i_am_taken_back_through_programme_steps_and_choose_new_answers
    expect(page).to have_path("/school/register-ect/state-school-appropriate-body")
    click_continue
    expect(page).to have_path("/school/register-ect/state-school-appropriate-body")
    expect(page.locator(".govuk-error-summary")).to be_visible
    page.get_by_role("combobox", name: "Enter appropriate body name")
        .first
        .select_option(value: @new_appropriate_body.name)
    click_continue

    expect(page).to have_path("/school/register-ect/training-programme")
    page.get_by_label("Provider-led").check
    click_continue

    expect(page).to have_path("/school/register-ect/lead-provider")
    page.get_by_label(@lead_provider.name).check
    click_continue
  end

  def and_i_do_not_see_old_lead_provider_on_check_answers
    expect(page).to have_path("/school/register-ect/check-answers")
    expect(page.get_by_text("Choices used by your school previously").count).to eq(0)
    expect(page.get_by_role("link", name: "Change appropriate body")).to be_visible
    expect(page.get_by_role("link", name: "Change lead provider")).to be_visible
  end

  def fill_in_trn_and_dob
    page.get_by_label("trn").fill("9876543")
    page.get_by_label("day").fill("3")
    page.get_by_label("month").fill("2")
    page.get_by_label("year").fill("1977")
  end

  def enter_start_date(date)
    page.get_by_label("day").fill(date.day.to_s)
    page.get_by_label("month").fill(date.month.to_s)
    page.get_by_label("year").fill(date.year.to_s)
  end

  def click_continue
    if page.get_by_role("link", name: "Continue").count.positive?
      page.get_by_role("link", name: "Continue").click
    else
      page.get_by_role("button", name: "Continue").click
    end
  end

  def click_confirm_and_continue
    page.get_by_role("button", name: "Confirm and continue").click
  end
end
