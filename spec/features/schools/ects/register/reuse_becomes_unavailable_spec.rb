RSpec.describe "Registering an ECT, reuse becomes unavailable", :enable_schools_interface do
  include_context "test trs api client"
  include ReusablePartnershipHelpers

  scenario "reuse chosen, start date changed to a year without a partnership, programme choices must be reselected" do
    travel_to(Date.new(2024, 6, 1)) do
      given_a_school_with_reusable_choices
      and_i_sign_in_as_that_school

      when_i_register_an_ect_and_choose_to_reuse_previous_choices
      then_i_see_reused_programme_choices_on_check_answers

      when_i_change_the_start_date_to_a_year_with_no_active_partnership
      and_i_am_taken_back_through_programme_steps_and_choose_new_answers
      then_i_see_new_programme_choices_on_check_answers
      then_i_do_not_see_reuse_row_on_check_answers
    end
  end

  def given_a_school_with_reusable_choices
    context = build_school_with_reusable_provider_led_partnership

    @school = context.school
    @current_contract_period = context.current_contract_period
    @previous_school_partnership = context.previous_school_partnership

    @old_lead_provider = context.last_chosen_lead_provider
    @delivery_partner  = context.previous_year_delivery_partner

    stub_reuse_finder_to_return(@previous_school_partnership)

    @future_contract_period = FactoryBot.create(:contract_period, :with_schedules, year: 2025)

    @new_lead_provider = FactoryBot.create(:lead_provider, name: "New Lead Provider")

    future_active_lp = FactoryBot.create(
      :active_lead_provider,
      lead_provider: @new_lead_provider,
      contract_period: @future_contract_period
    )

    FactoryBot.create(
      :lead_provider_delivery_partnership,
      active_lead_provider: future_active_lp,
      delivery_partner: @delivery_partner
    )

    @old_appropriate_body = @school.last_chosen_appropriate_body
    @new_appropriate_body = FactoryBot.create(:appropriate_body, name: "New Appropriate Body")
  end

  def stub_reuse_finder_to_return(previous_partnership)
    @reuse_finder = instance_double(SchoolPartnerships::FindPreviousReusable)

    allow(SchoolPartnerships::FindPreviousReusable).to receive(:new)
      .and_return(@reuse_finder)

    allow(@reuse_finder).to receive(:call)
      .and_return(previous_partnership)
  end

  def and_i_sign_in_as_that_school
    sign_in_as_school_user(school: @school)
  end

  def when_i_register_an_ect_and_choose_to_reuse_previous_choices
    page.goto "/school/home/ects"
    page.get_by_role("link", name: "Register an ECT starting at your school").click

    click_continue
    fill_in_trn_and_dob

    page.get_by_role("button", name: "Continue").click
    expect(page).to have_path("/school/register-ect/review-ect-details")

    page.get_by_label("Yes").check
    click_confirm_and_continue

    page.fill('input[type="email"]', "example@example.com")
    click_continue

    enter_start_date(@current_contract_period.started_on + 1.month)
    click_continue

    page.get_by_label("Full time").check
    click_continue

    expect(page).to have_path("/school/register-ect/use-previous-ect-choices")
    page.get_by_label("Yes").check
    click_continue
  end

  def then_i_see_reused_programme_choices_on_check_answers
    expect(page).to have_path("/school/register-ect/check-answers")

    expect(page.get_by_text("Choices used by your school previously").first).to be_visible
    expect(page.get_by_text(@old_lead_provider.name).first).to be_visible
    expect(page.get_by_text(@old_appropriate_body.name).first).to be_visible
  end

  def when_i_change_the_start_date_to_a_year_with_no_active_partnership
    page.get_by_role("link", name: "Change school start date").click

    allow(@reuse_finder).to receive(:call).and_return(nil)

    enter_start_date(@future_contract_period.started_on + 1.month)
    click_continue
  end

  def and_i_am_taken_back_through_programme_steps_and_choose_new_answers
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
    page.get_by_label(@new_lead_provider.name).check
    click_continue
  end

  def then_i_see_new_programme_choices_on_check_answers
    expect(page).to have_path("/school/register-ect/check-answers")

    expect(page.get_by_text(@new_appropriate_body.name).first).to be_visible
    expect(page.get_by_text(@new_lead_provider.name).first).to be_visible

    expect(page.get_by_text(@old_appropriate_body.name).count).to eq(0)
    expect(page.get_by_text(@old_lead_provider.name).count).to eq(0)
  end

  def then_i_do_not_see_reuse_row_on_check_answers
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
    if page.get_by_role("button", name: "Continue").count.positive?
      page.get_by_role("button", name: "Continue").click
    else
      page.get_by_role("link", name: "Continue").click
    end
  end

  def click_confirm_and_continue
    page.get_by_role("button", name: "Confirm and continue").click
  end
end
