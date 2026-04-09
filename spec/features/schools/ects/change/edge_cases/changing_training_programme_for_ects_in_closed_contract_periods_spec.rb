describe "Changing training programme for ECTs who started provider-led training in a closed contract period", :enable_schools_interface do
  before do
    given_there_is_a_school
    and_there_is_a_closed_contract_period
    and_there_is_an_open_contract_period_with_extended_schedules
    and_there_was_a_school_partnership_in_the_closed_period
    and_there_is_another_lead_provider

    and_there_is_an_ect
    with_a_mentor
    and_the_ect_started_provider_led_training_in_a_closed_contract_period
    and_the_ect_switched_to_school_led_training
  end

  it "changes the training programme from school-led to provider-led" do
    and_there_is_an_active_lead_provider_in_the_open_contract_period
    and_there_is_a_third_active_lead_provider

    when_i_am_logged_in_as_a_school_user
    and_i_visit_the_ect_page
    then_i_can_change_the_training_programme

    when_i_change_the_training_programme
    then_i_can_choose_from_lead_providers_who_are_active_in_the_open_contract_period

    when_i_choose_the_lead_provider
    and_i_continue
    then_i_am_asked_to_check_and_confirm_the_change

    when_i_confirm_the_change
    then_i_see_the_provider_led_confirmation_message

    when_i_visit_the_ect_page
    then_the_ects_training_is_awaiting_confirmation_from_the_new_lead_provider
    and_a_training_period_has_been_created_with_an_expression_of_interest_in_the_open_contract_period
    and_the_school_led_training_period_has_been_finished
    and_the_provider_led_training_period_has_been_left_in_the_original_contract_period
    and_the_ect_has_payments_frozen_year_set
  end

  it "changes the training programme from school-led to provider-led, with an existing school partnership" do
    and_there_is_a_school_partnership_in_the_open_contract_period
    and_there_is_a_third_active_lead_provider

    when_i_am_logged_in_as_a_school_user
    and_i_visit_the_ect_page
    then_i_can_change_the_training_programme

    when_i_change_the_training_programme
    then_i_can_choose_from_lead_providers_who_are_active_in_the_open_contract_period

    when_i_choose_the_lead_provider
    and_i_continue
    then_i_am_asked_to_check_and_confirm_the_change

    when_i_confirm_the_change
    then_i_see_the_provider_led_confirmation_message

    when_i_visit_the_ect_page
    then_the_ects_training_is_confirmed_with_the_existing_school_partnership
    and_a_training_period_has_been_created_with_a_school_partnership_in_the_open_contract_period
    and_the_school_led_training_period_has_been_finished
    and_the_provider_led_training_period_has_been_left_in_the_original_contract_period
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

  def and_there_is_another_lead_provider
    @lead_provider = FactoryBot.create(:lead_provider, name: "Other Lead Provider")
  end

  def and_there_is_an_active_lead_provider_in_the_open_contract_period
    @other_active_lead_provider = FactoryBot.create(
      :active_lead_provider,
      :for_year,
      year: 2024,
      lead_provider: @lead_provider
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

  def and_there_is_a_school_partnership_in_the_open_contract_period
    @other_school_partnership = FactoryBot.create(:school_partnership,
                                                  :with_active_lead_provider,
                                                  :for_year, year: 2024,
                                                             school: @school, lead_provider: @lead_provider)
    @other_active_lead_provider = @other_school_partnership.active_lead_provider
  end

  def and_there_is_an_ect
    @teacher = FactoryBot.create(
      :teacher,
      trs_first_name: "John",
      trs_last_name: "Doe"
    )
    @ect_at_school_period = FactoryBot.create(
      :ect_at_school_period,
      :ongoing,
      started_on: Date.new(2021, 9, 1),
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
      started_on: @ect_at_school_period.started_on
    )
    FactoryBot.create(:mentorship_period, mentee: @ect_at_school_period, mentor: mentor_at_school_period)
  end

  def and_the_ect_started_provider_led_training_in_a_closed_contract_period
    @provider_led_training_period = FactoryBot.create(:training_period, :for_ect, :finished, :provider_led,
                                                      ect_at_school_period: @ect_at_school_period,
                                                      school_partnership: @school_partnership,
                                                      started_on: @ect_at_school_period.started_on)
  end

  def and_the_ect_switched_to_school_led_training
    @school_led_training_period = FactoryBot.create(:training_period, :for_ect, :ongoing, :school_led, ect_at_school_period: @ect_at_school_period, started_on: @provider_led_training_period.finished_on + 1.day)
  end

  def when_i_am_logged_in_as_a_school_user
    sign_in_as_school_user(school: @school)
  end

  def and_i_visit_the_ect_page
    page.goto(schools_ect_path(@ect_at_school_period))
  end

  alias_method :when_i_visit_the_ect_page, :and_i_visit_the_ect_page

  def then_i_can_change_the_training_programme
    row = page.locator(".govuk-summary-list__row", hasText: "Training programme")
    row.get_by_role("link", name: "Change").click
  end

  def when_i_change_the_training_programme
    page.get_by_role("button", name: "Change training programme").click
  end

  def then_i_can_choose_from_lead_providers_who_are_active_in_the_open_contract_period
    expect(page.get_by_label("Other Lead Provider")).to be_visible
    expect(page.get_by_label("A Third Lead Provider")).not_to be_visible
  end

  def when_i_choose_the_lead_provider
    page.get_by_label("Other Lead Provider").check
  end

  def when_i_continue
    page.get_by_role("button", name: "Continue").click
  end

  alias_method :and_i_continue, :when_i_continue

  def then_i_am_asked_to_check_and_confirm_the_change
    heading = page.locator("h1", hasText: "Check and confirm change")
    expect(heading).to be_visible
  end

  def when_i_confirm_the_change
    page.get_by_role("button", name: "Confirm change").click
  end

  def then_i_see_the_provider_led_confirmation_message
    success_panel = page.locator(".govuk-panel")
    expect(success_panel).to have_text(
      "You’ve changed John Doe’s training programme to provider-led with Other Lead Provider"
    )
  end

  def and_a_training_period_has_been_created_with_an_expression_of_interest_in_the_open_contract_period
    @ect_at_school_period.reload
    new_training_period = @ect_at_school_period.training_periods.last
    expect(new_training_period.expression_of_interest_contract_period.year).to eq(2024)
  end

  def and_a_training_period_has_been_created_with_a_school_partnership_in_the_open_contract_period
    @ect_at_school_period.reload
    new_training_period = @ect_at_school_period.training_periods.last
    expect(new_training_period.contract_period.year).to eq(2024)
  end

  def and_the_ect_has_payments_frozen_year_set
    teacher = @ect_at_school_period.teacher.reload
    expect(teacher.ect_payments_frozen_year).to eq(2021)
  end

  def and_the_school_led_training_period_has_been_finished
    @school_led_training_period.reload
    expect(@school_led_training_period.finished_on).to eq(Date.current)
  end

  def and_the_provider_led_training_period_has_been_left_in_the_original_contract_period
    @provider_led_training_period.reload
    expect(@provider_led_training_period.contract_period.year).to eq(2021)
  end

  def then_the_ects_training_is_confirmed_with_the_existing_school_partnership
    expect(page.get_by_text("Confirmed by Other Lead Provider")).to be_visible
  end

  def then_the_ects_training_is_awaiting_confirmation_from_the_new_lead_provider
    expect(page.get_by_text("Awaiting confirmation by Other Lead Provider")).to be_visible
  end
end
