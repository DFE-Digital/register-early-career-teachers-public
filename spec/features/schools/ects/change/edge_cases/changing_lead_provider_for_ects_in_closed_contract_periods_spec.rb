describe "School user can change ECT's lead provider", :enable_schools_interface do
  include_context "safe_schedules"

  it "changes the lead provider" do
    given_there_is_a_school
    and_there_is_a_closed_contract_period
    and_there_is_an_open_contract_period_with_extended_schedules
    and_there_is_a_school_partnership
    and_there_is_an_ect_who_started_in_a_closed_contract_period
    with_confirmed_provider_led_training
    and_there_is_an_active_lead_provider_in_the_open_contract_period
    and_there_is_a_third_active_lead_provider
    and_i_am_logged_in_as_a_school_user

    when_i_visit_the_ect_page
    then_i_can_change_the_assigned_lead_provider
    and_i_see_the_change_lead_provider_form
    and_the_current_lead_provider_is_not_an_option
    and_the_third_active_lead_provider_is_not_an_option

    when_i_choose_lead_provider("Other Lead Provider")
    and_i_continue
    then_i_am_asked_to_check_and_confirm_the_change

    when_i_confirm_the_change
    then_i_see_the_confirmation_message
    and_the_ect_has_payments_frozen_year_set
  end

private

  def given_there_is_a_school
    @school = FactoryBot.create(:school)
  end

  def and_there_is_an_ect_who_started_in_a_closed_contract_period
    @teacher = FactoryBot.create(
      :teacher,
      trs_first_name: "John",
      trs_last_name: "Doe"
    )
    @ect_at_school_period = FactoryBot.create(
      :ect_at_school_period,
      :ongoing,
      teacher: @teacher,
      school: @school,
      email: "ect@example.com",
      started_on: Date.new(2021, 9, 1)
    )
  end

  def and_there_is_a_closed_contract_period
    FactoryBot.create(:contract_period, :with_schedules, :with_payments_frozen, year: 2021)
  end

  def and_there_is_an_open_contract_period_with_extended_schedules
    open_contract_period = FactoryBot.create(:contract_period, :with_schedules, year: 2024)
    FactoryBot.create(:schedule, contract_period: open_contract_period, identifier: "ecf-extended-september")
  end

  def and_there_is_a_school_partnership
    @school_partnership = FactoryBot.create(:school_partnership, :with_active_lead_provider, :for_year, year: 2021, school: @school)
  end

  def with_confirmed_provider_led_training
    @provider_led_training_period = FactoryBot.create(
      :training_period,
      :ongoing,
      :for_ect,
      :provider_led,
      :with_school_partnership,
      ect_at_school_period: @ect_at_school_period,
      started_on: @ect_at_school_period.started_on,
      school_partnership: @school_partnership
    )
  end

  def and_there_is_an_active_lead_provider_in_the_open_contract_period
    lead_provider = FactoryBot.create(:lead_provider, name: "Other Lead Provider")
    @other_active_lead_provider = FactoryBot.create(
      :active_lead_provider,
      :for_year,
      year: 2024,
      lead_provider:
    )
  end

  def and_there_is_a_third_active_lead_provider
    lead_provider = FactoryBot.create(:lead_provider, name: "A Third Testing Provider")
    @third_active_lead_provider = FactoryBot.create(
      :active_lead_provider,
      :for_year,
      year: 2025,
      lead_provider:
    )
  end

  def and_i_am_logged_in_as_a_school_user
    sign_in_as_school_user(school: @school)
  end

  def when_i_visit_the_ect_page
    page.goto(schools_ect_path(@ect_at_school_period))
  end

  def then_i_can_change_the_assigned_lead_provider
    row = page.locator(".govuk-summary-list__row", hasText: "Lead provider")
    row.get_by_role("link", name: "Change").click
  end

  def and_i_see_the_change_lead_provider_form
    heading = page.locator("h1")
    expect(heading).to have_text("Change lead provider for John Doe")
  end

  def and_the_current_lead_provider_is_not_an_option
    expect(page.get_by_text(@school_partnership.lead_provider.name)).not_to be_visible
  end

  def and_the_third_active_lead_provider_is_not_an_option
    expect(page.get_by_text(@third_active_lead_provider.lead_provider.name)).not_to be_visible
  end

  def when_i_choose_lead_provider(name)
    page.get_by_label(name).check
    @selected_lead_provider_name = name
  end

  def and_i_continue
    page.get_by_role("button", name: "Continue").click
  end

  def then_i_am_asked_to_check_and_confirm_the_change
    heading = page.locator("h1")
    expect(heading).to have_text("Check and confirm change")
  end

  def when_i_confirm_the_change
    page.get_by_role("button", name: "Confirm change").click
  end

  def then_i_see_the_confirmation_message
    success_panel = page.locator(".govuk-panel")
    expect(success_panel).to have_text(
      "You have chosen #{@selected_lead_provider_name} as the new lead provider for John Doe"
    )
  end

  def and_the_ect_has_payments_frozen_year_set
    @ect_at_school_period.teacher.reload
    expect(@ect_at_school_period.teacher.ect_payments_frozen_year).to eq(2021)
  end
end
