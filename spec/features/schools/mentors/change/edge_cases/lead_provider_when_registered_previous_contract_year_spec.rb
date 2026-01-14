describe "School user can change a mentor's lead provider", :enable_schools_interface do
  around do |example|
    travel_to(Date.new(2025, 9, 1)) { example.run }
  end

  before do
    given_there_is_a_school
    and_there_is_a_mentor
    and_i_am_logged_in_as_a_school_user

    and_there_is_a_contract_period
    and_there_are_active_lead_providers
    with_provider_led_training
    and_there_are_other_active_lead_providers
  end

  context "when the mentor was registered in a previous contract year and the lead provider was not active that year" do
    it "creates a new expression of interest" do
      when_i_visit_the_mentor_page
      then_i_can_change_the_assigned_lead_provider
      and_i_see_the_change_lead_provider_form
      and_the_current_lead_provider_is_not_an_option

      when_i_choose_a_lead_provider
      and_i_continue
      then_i_am_asked_to_check_and_confirm_the_change
      and_i_confirm_the_change
      then_i_see_the_confirmation_message

      when_i_visit_the_mentor_page
      then_i_see_there_is_a_new_expression_of_interest
      and_a_new_training_period_should_be_created_in_the_original_contract_year
    end
  end

private

  def given_there_is_a_school
    @school = FactoryBot.create(:school)
  end

  def and_there_is_a_mentor
    @teacher = FactoryBot.create(
      :teacher,
      trs_first_name: "John",
      trs_last_name: "Doe"
    )
    @mentor_at_school_period = FactoryBot.create(
      :mentor_at_school_period,
      :ongoing,
      teacher: @teacher,
      school: @school,
      started_on: Date.new(2024, 9, 1)
    )
  end

  def and_there_is_a_contract_period
    @contract_period_2024 = FactoryBot.create(:contract_period, :with_schedules, year: 2024)
    @contract_period_2025 = FactoryBot.create(:contract_period, :with_schedules, year: 2025)
  end

  def and_there_are_active_lead_providers
    lead_provider = FactoryBot.create(:lead_provider, name: "Testing Provider")
    @active_lead_provider = FactoryBot.create(
      :active_lead_provider,
      lead_provider:,
      contract_period: @contract_period_2024
    )
    lead_provider_delivery_partnership = FactoryBot.create(
      :lead_provider_delivery_partnership,
      active_lead_provider: @active_lead_provider,
      contract_period: @contract_period_2024
    )
    @school_partnership = FactoryBot.create(
      :school_partnership,
      school: @school,
      lead_provider_delivery_partnership:
    )
  end

  def with_provider_led_training
    @provider_led_training_period = FactoryBot.create(
      :training_period,
      :ongoing,
      :for_mentor,
      :provider_led,
      school_partnership: @school_partnership,
      mentor_at_school_period: @mentor_at_school_period,
      started_on: @mentor_at_school_period.started_on
    )
  end

  def and_there_are_other_active_lead_providers
    lead_provider = FactoryBot.create(:lead_provider, name: "Other Lead Provider")
    FactoryBot.create(
      :active_lead_provider,
      contract_period: @contract_period_2024,
      lead_provider:
    )

    @other_active_lead_provider = FactoryBot.create(
      :active_lead_provider,
      contract_period: @contract_period_2025,
      lead_provider:
    )
  end

  def with_a_partnership_with_the_school
    lead_provider_delivery_partnership = FactoryBot.create(:lead_provider_delivery_partnership,
                                                           active_lead_provider: @other_active_lead_provider,
                                                           contract_period: @contract_period_2025)
    @other_school_partnership = FactoryBot.create(
      :school_partnership,
      school: @school,
      lead_provider_delivery_partnership:
    )
  end

  def and_i_am_logged_in_as_a_school_user
    sign_in_as_school_user(school: @school)
  end

  def when_i_visit_the_mentor_page
    page.goto(schools_mentor_path(@mentor_at_school_period))
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
    expect(page.get_by_label("Testing Provider")).not_to be_visible
  end

  def when_i_choose_a_lead_provider
    page.get_by_label("Other Lead Provider").check
  end

  def and_i_continue
    page.get_by_role("button", name: "Continue").click
  end

  alias_method :when_i_continue, :and_i_continue

  def then_i_am_asked_to_check_and_confirm_the_change
    heading = page.locator("h1")
    expect(heading).to have_text("Check and confirm change")
  end

  def and_i_confirm_the_change
    page.get_by_role("button", name: "Confirm change").click
  end

  def then_i_see_the_confirmation_message
    page.screenshot(path: "tmp/sucess.png")

    success_panel = page.locator(".govuk-panel")
    expect(success_panel).to have_text(
      "You have chosen Other Lead Provider as the new lead provider for John Doe"
    )
  end

  def then_i_see_there_is_a_new_expression_of_interest
    row = page.locator(".govuk-summary-list__row", hasText: "Lead provider").first

    expect(row)
    .to have_text("Awaiting confirmation by Other Lead Provider")
  end

  def and_a_new_training_period_should_be_created_in_the_original_contract_year
    training_periods = @mentor_at_school_period.training_periods
    expect(training_periods.count).to eq(2)

    new_training_period = training_periods.ongoing.first

    expect(new_training_period).not_to be_nil
    expect(new_training_period.school_partnership).to be_nil
    expect(new_training_period.schedule.contract_period_year).to eq(2024)
  end
end
