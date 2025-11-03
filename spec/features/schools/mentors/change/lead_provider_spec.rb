describe "School user can change a mentor's lead provider", :enable_schools_interface do
  before do
    given_there_is_a_school
    and_there_is_a_mentor
    and_i_am_logged_in_as_a_school_user

    and_there_is_a_contract_period
    and_there_is_an_active_lead_provider
    with_provider_led_training
    and_there_is_another_active_lead_provider
  end

  context 'when an active lead provider is selected' do
    it "changes the lead provider to an active lead provider" do
      with_a_partnership_with_the_school

      when_i_visit_the_mentor_page
      then_i_can_change_the_assigned_lead_provider
      and_i_see_the_change_lead_provider_form
      and_the_current_lead_provider_is_not_an_option

      when_i_choose_a_lead_provider
      and_i_continue
      then_i_am_asked_to_check_and_confirm_the_change

      when_i_navigate_back_to_the_form
      and_i_see_the_change_lead_provider_form
      then_the_lead_provider_is_selected

      when_i_continue
      and_i_confirm_the_change
      then_i_see_the_confirmation_message

      when_i_visit_the_mentor_page
      then_i_see_the_new_lead_provider_is_assigned
    end
  end

  context 'when a lead provider without a partnership is selected' do
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
    end
  end

private

  def given_there_is_a_school
    @school = FactoryBot.create(:school)
  end

  def and_there_is_a_school_partnership
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
      # email: "ect@example.com",
      started_on: 1.week.ago
    )
  end

  def and_there_is_a_contract_period
    @contract_period = FactoryBot.create(:contract_period, :current)
  end

  def and_there_is_an_active_lead_provider
    lead_provider = FactoryBot.create(:lead_provider, name: "Testing Provider")
    @active_lead_provider = FactoryBot.create(
      :active_lead_provider,
      lead_provider:,
      contract_period: @contract_period
    )
    lead_provider_delivery_partnership = FactoryBot.create(
      :lead_provider_delivery_partnership,
      active_lead_provider: @active_lead_provider,
      contract_period: @contract_period
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

  def and_there_is_another_active_lead_provider
    lead_provider = FactoryBot.create(:lead_provider, name: "Other Lead Provider")
    @other_active_lead_provider = FactoryBot.create(
      :active_lead_provider,
      contract_period: @contract_period,
      lead_provider:
    )
  end

  def with_a_partnership_with_the_school
    lead_provider_delivery_partnership = FactoryBot.create(:lead_provider_delivery_partnership,
                                                           active_lead_provider: @other_active_lead_provider,
                                                           contract_period: @contract_period)
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

  def when_i_navigate_back_to_the_form
    page.get_by_role("link", name: "Back", exact: true).click
  end

  def then_the_lead_provider_is_selected
    lead_provider_radio = page.get_by_label("Other Lead Provider")
    expect(lead_provider_radio).to be_checked
  end

  def and_i_confirm_the_change
    page.get_by_role("button", name: "Confirm change").click
  end

  def then_i_see_the_confirmation_message
    success_panel = page.locator(".govuk-panel")
    expect(success_panel).to have_text(
      "You have chosen Other Lead Provider as the new lead provider for John Doe"
    )
  end

  def then_i_see_the_new_lead_provider_is_assigned
    row = page.locator(".govuk-summary-list__row", hasText: "Lead provider").first

    expect(row)
    .to have_text("Confirmed by Other Lead Provider")
  end

  def then_i_see_there_is_a_new_expression_of_interest
    row = page.locator(".govuk-summary-list__row", hasText: "Lead provider").first

    expect(row)
    .to have_text("Awaiting confirmation by Other Lead Provider")
  end
end
