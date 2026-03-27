describe "School user can change ECTs training programme to provider lead", :enable_schools_interface do
  include_context "safe_schedules"

  it "changes the training programme from school-led to provider-led" do
    given_there_is_a_school
    and_there_is_a_closed_contract_period
    and_there_is_an_open_contract_period_with_extended_schedules
    and_there_was_a_school_partnership_in_the_closed_period
    and_there_is_an_ect
    with_a_mentor
    and_the_ect_started_provider_led_training_in_a_closed_contract_period
    and_switched_to_school_led_training
    
    when_i_am_logged_in_as_a_school_user
    and_i_visit_the_ect_page
    then_i_can_change_the_training_programme_to_provider_led

    when_i_change_the_training_programme_to_provider_led
    then_i_can_choose_from_lead_providers_who_are_active_in_the_open_contract_period
    
    when_i_choose_the_lead_provider
    and_i_continue
    then_i_am_asked_to_check_and_confirm_the_change

    when_i_confirm_the_change
    then_i_see_the_provider_led_confirmation_message
    and_a_training_period_has_been_created_in_the_open_contract_period
    and_the_school_led_training_period_has_been_finished
    and_the_ect_has_payments_frozen_year_set
  end


private

  def given_there_is_a_school
    @school = FactoryBot.create(:school)
  end

  def and_there_is_a_closed_contract_period
    FactoryBot.create(:contract_period, :with_schedules, :with_payments_frozen, year: 2021)
  end

  def and_there_is_an_open_contract_period_with_extended_schedules
    open_contract_period = FactoryBot.create(:contract_period, :with_schedules, year: 2024)
    FactoryBot.create(:schedule, contract_period: open_contract_period, identifier: "ecf-extended-september")
  end

  def and_there_was_a_school_partnership_in_the_closed_period
    @school_partnership = FactoryBot.create(:school_partnership, :with_active_lead_provider, :for_year, year: 2021, school: @school)
  end

  def and_there_is_an_ect
    @teacher = FactoryBot.create(
      :teacher,
      trs_first_name: "John",
      trs_last_name: "Doe"
    )
    @ect = FactoryBot.create(
      :ect_at_school_period,
      :ongoing,
      started_on: 1.day.ago,
      teacher: @teacher,
      school: @school,
      email: "ect@example.com"
    )
  end

  def with_a_mentor
    mentor_at_school_period = FactoryBot.create(
      :mentor_at_school_period,
      :ongoing,
      school: @school,
      started_on: @ect.started_on
    )
    FactoryBot.create(:mentorship_period, mentee: @ect, mentor: mentor_at_school_period)
  end

  def and_there_is_a_contract_period
    @contract_period = FactoryBot.create(:contract_period, :current, :with_schedules)
  end

  def and_there_is_an_active_lead_provider
    lead_provider = FactoryBot.create(:lead_provider, name: "Testing Provider")
    @active_lead_provider = FactoryBot.create(
      :active_lead_provider,
      contract_period: @contract_period,
      lead_provider:
    )
  end

  def and_the_ect_started_provider_led_training_in_a_closed_contract_period
    @first_training_period = FactoryBot.create(:training_period, :for_ect, :finished, :provider_led, ect_at_school_period:, school_partnership:, started_on:)
    
  end

  def and_then_the_ect_switched_to_school_led_training
    FactoryBot.create(:training_period, :for_ect, :ongoing, :school_led, ect_at_school_period:, started_on: @first_training_period.finished_on + 1.day)
  end

  def with_provider_led_training
    FactoryBot.create(
      :training_period,
      :provider_led,
      :for_ect,
      :ongoing,
      ect_at_school_period: @ect,
      started_on: @ect.started_on
    )
  end

  def with_school_led_training
    FactoryBot.create(
      :training_period,
      :school_led,
      :for_ect,
      :ongoing,
      ect_at_school_period: @ect,
      started_on: @ect.started_on
    )
  end

  def and_i_am_logged_in_as_a_school_user
    sign_in_as_school_user(school: @school)
  end

  def when_i_visit_the_ect_page
    page.goto(schools_ect_path(@ect))
  end

  def then_i_can_change_the_training_programme
    row = page.locator(".govuk-summary-list__row", hasText: "Training programme")
    row.get_by_role("link", name: "Change").click
  end

  def and_i_can_change_the_training_programme_to_school_led
    heading = page.locator("h1", hasText: "Change John Doe’s training programme to school-led")
    expect(heading).to be_visible
  end

  def and_i_can_change_the_training_programme_to_provider_led
    heading = page.locator("h1", hasText: "Change John Doe’s training programme to provider-led")
    expect(heading).to be_visible
  end

  def when_i_change_the_training_programme
    page.get_by_role("button", name: "Change training programme").click
  end

  def and_i_choose_the_lead_provider
    page.get_by_label("Testing Provider").check
  end

  def when_i_continue
    page.get_by_role("button", name: "Continue").click
  end

  alias_method :and_i_continue, :when_i_continue

  def then_i_am_asked_to_check_and_confirm_the_change
    heading = page.locator("h1", hasText: "Check and confirm change")
    expect(heading).to be_visible
  end

  def when_i_navigate_back_to_the_form
    page.get_by_role("link", name: "Back", exact: true).click
  end

  def then_the_lead_provider_is_selected
    lead_provider_radio = page.get_by_label("Testing Provider")
    expect(lead_provider_radio).to be_checked
  end

  def and_i_confirm_the_change
    page.get_by_role("button", name: "Confirm change").click
  end

  def then_i_see_the_provider_led_confirmation_message
    success_panel = page.locator(".govuk-panel")
    expect(success_panel).to have_text(
      "You have changed John Doe’s training programme to provider-led with Testing Provider"
    )
  end

  def then_i_see_the_school_led_confirmation_message
    success_panel = page.locator(".govuk-panel")
    expect(success_panel).to have_text(
      "You have changed John Doe’s training programme to school-led"
    )
  end

  def and_a_training_period_has_been_created_in_the_open_contract_period
    @ect_at_school_period.reload
    new_training_period = @ect_at_school_period.training_periods.last
    expect(new_training_period.expression_of_interest_contract_period.year).to eq(2024)
  end

  def and_the_school_led_training_period_has_been_finished
    @provider_led_training_period.reload
    expect(@provider_led_training_period.finished_on).to eq(Date.current)
  end

  def and_the_ect_has_payments_frozen_year_set
    @ect_at_school_period.teacher.reload
    expect(@ect_at_school_period.teacher.ect_payments_frozen_year).to eq(2021)
  end
end
