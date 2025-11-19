describe "School user can change ECTs training programme", :enable_schools_interface do
  it "changes the training programme from provider-led to school-led" do
    given_there_is_a_school
    and_there_is_an_ect
    with_provider_led_training
    and_i_am_logged_in_as_a_school_user

    when_i_visit_the_ect_page
    then_i_can_change_the_training_programme
    and_i_can_change_the_training_programme_to_school_led

    when_i_change_the_training_programme
    then_i_am_asked_to_check_and_confirm_the_change

    when_i_navigate_back_to_the_form
    and_i_can_change_the_training_programme_to_school_led

    when_i_change_the_training_programme
    and_i_confirm_the_change
    then_i_see_the_school_led_confirmation_message
  end

  it "changes the training programme from school-led to provider-led" do
    given_there_is_a_school
    and_there_is_an_ect
    and_there_is_a_contract_period
    and_there_is_an_active_lead_provider
    with_school_led_training
    and_i_am_logged_in_as_a_school_user

    when_i_visit_the_ect_page
    then_i_can_change_the_training_programme
    and_i_can_change_the_training_programme_to_provider_led

    when_i_change_the_training_programme
    and_i_choose_the_lead_provider
    and_i_continue
    then_i_am_asked_to_check_and_confirm_the_change

    when_i_navigate_back_to_the_form
    then_the_lead_provider_is_selected

    when_i_continue
    and_i_confirm_the_change
    then_i_see_the_provider_led_confirmation_message
  end

private

  def given_there_is_a_school
    @school = FactoryBot.create(:school)
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
end
