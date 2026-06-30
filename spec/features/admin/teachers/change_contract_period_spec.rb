describe "Admin changes a teacher's contract period" do
  around do |example|
    travel_to(Date.new(2026, 2, 1)) { example.run }
  end

  it "finishes the current active provider-led training period and starts a replacement using a matching partnership" do
    given_there_is_a_school
    and_there_is_a_teacher
    and_there_are_contract_periods_and_schedules
    and_there_is_a_current_active_provider_led_training_period
    and_i_am_logged_in_as_a_finance_user

    when_i_visit_the_training_tab
    then_i_can_start_the_contract_period_change_journey

    when_i_select_the_new_contract_period
    then_i_can_choose_the_matching_partnership

    when_i_select_the_matching_partnership
    then_i_see_the_check_answers_page

    when_i_confirm_the_contract_period_change
    then_i_see_the_contract_period_changed_banner_on_the_training_tab
    and_the_old_training_period_is_finished
    and_a_replacement_training_period_is_created
  end

  it "updates a future starting EOI only training period in place" do
    given_there_is_a_school
    and_there_is_a_teacher
    and_there_are_contract_periods_and_schedules
    and_there_is_a_future_starting_eoi_only_training_period
    and_i_am_logged_in_as_a_finance_user

    when_i_visit_the_training_tab
    then_i_can_start_the_contract_period_change_journey

    when_i_select_the_new_contract_period
    then_i_skip_partnership_selection_and_see_check_answers

    when_i_confirm_the_contract_period_change
    then_i_see_the_contract_period_changed_banner_on_the_training_tab
    and_the_same_future_training_period_is_updated_in_place
    and_the_future_training_period_remains_eoi_only
  end

private

  def given_there_is_a_school
    @school = FactoryBot.create(:school)
  end

  def and_there_is_a_teacher
    @teacher = FactoryBot.create(
      :teacher,
      trs_first_name: "Bruce",
      trs_last_name: "Wayne"
    )
    @teacher_name = Teachers::Name.new(@teacher).full_name
    @ect_at_school_period = FactoryBot.create(
      :ect_at_school_period,
      :ongoing,
      teacher: @teacher,
      school: @school,
      started_on: Date.current.prev_year
    )
  end

  def and_there_are_contract_periods_and_schedules
    @current_contract_period = FactoryBot.create(:contract_period, year: 2025)
    @target_contract_period = FactoryBot.create(:contract_period, year: 2026)
    @current_schedule = FactoryBot.create(:schedule, contract_period: @current_contract_period)
    @target_schedule = FactoryBot.create(
      :schedule,
      contract_period: @target_contract_period,
      identifier: @current_schedule.identifier
    )
  end

  def and_there_is_a_current_active_provider_led_training_period
    lead_provider = FactoryBot.create(:lead_provider, name: "Best Lead Provider")
    delivery_partner = FactoryBot.create(:delivery_partner, name: "Trusted Delivery Partner")

    @current_school_partnership = FactoryBot.create(
      :school_partnership,
      :for_year,
      year: @current_contract_period.year,
      school: @school,
      lead_provider:,
      delivery_partner:
    )
    @target_school_partnership = FactoryBot.create(
      :school_partnership,
      :for_year,
      year: @target_contract_period.year,
      school: @school,
      lead_provider:,
      delivery_partner:
    )
    @target_partnership_name = "#{lead_provider.name} & #{delivery_partner.name}"
    @training_period = FactoryBot.create(
      :training_period,
      :ongoing,
      ect_at_school_period: @ect_at_school_period,
      school_partnership: @current_school_partnership,
      schedule: @current_schedule,
      started_on: Date.current.prev_month
    )
  end

  def and_there_is_a_future_starting_eoi_only_training_period
    lead_provider = FactoryBot.create(:lead_provider, name: "EOI Lead Provider")
    current_active_lead_provider = FactoryBot.create(
      :active_lead_provider,
      lead_provider:,
      contract_period: @current_contract_period
    )
    @target_active_lead_provider = FactoryBot.create(
      :active_lead_provider,
      lead_provider:,
      contract_period: @target_contract_period
    )
    @training_period = FactoryBot.create(
      :training_period,
      :ongoing,
      :with_only_expression_of_interest,
      ect_at_school_period: @ect_at_school_period,
      expression_of_interest: current_active_lead_provider,
      schedule: @current_schedule,
      started_on: Date.current.next_month,
      finished_on: nil
    )
    @original_training_period_id = @training_period.id
    @original_training_period_count = TrainingPeriod.where(ect_at_school_period: @ect_at_school_period).count
  end

  def and_i_am_logged_in_as_a_finance_user
    sign_in_as_dfe_user(role: :finance)
  end

  def when_i_visit_the_training_tab
    page.goto(admin_teacher_training_path(@teacher))
  end

  def then_i_can_start_the_contract_period_change_journey
    contract_period_row = page.locator(".govuk-summary-list__row", hasText: "Contract period")
    contract_period_row.get_by_role("link", name: "Change").click

    expect(page.locator("h1", hasText: "Select new contract period for #{@teacher_name}")).to be_visible
  end

  def when_i_select_the_new_contract_period
    page.get_by_label(@target_contract_period.year.to_s).check
    page.get_by_role("button", name: "Continue").click
  end

  def then_i_can_choose_the_matching_partnership
    expect(page.locator("h1", hasText: "Select #{@target_contract_period.year} partnership for #{@teacher_name}")).to be_visible
    expect(page.get_by_label(@target_partnership_name)).to be_visible
  end

  def when_i_select_the_matching_partnership
    page.get_by_label(@target_partnership_name).check
    page.get_by_role("button", name: "Continue").click
  end

  def then_i_see_the_check_answers_page
    expect(page.locator("h1", hasText: "Confirm contract period change for #{@teacher_name}")).to be_visible
    expect(page.locator(".govuk-summary-list__row", hasText: "Existing contract period")).to have_text(@current_contract_period.year.to_s)
    expect(page.locator(".govuk-summary-list__row", hasText: "New contract period")).to have_text(@target_contract_period.year.to_s)
    expect(page.locator(".govuk-summary-list__row", hasText: "Partnership")).to have_text(@target_partnership_name)
  end

  def then_i_skip_partnership_selection_and_see_check_answers
    expect(page.locator("h1", hasText: "Confirm contract period change for #{@teacher_name}")).to be_visible
    expect(page.locator(".govuk-summary-list__row", hasText: "Existing contract period")).to have_text(@current_contract_period.year.to_s)
    expect(page.locator(".govuk-summary-list__row", hasText: "New contract period")).to have_text(@target_contract_period.year.to_s)
    expect(page.locator(".govuk-summary-list__row", hasText: "Lead provider")).to have_text("EOI Lead Provider")
    expect(page.locator(".govuk-summary-list__row", hasText: "Delivery partner")).to have_text("No delivery partner confirmed")
  end

  def when_i_confirm_the_contract_period_change
    page.get_by_role("button", name: "Confirm").click
  end

  def then_i_see_the_contract_period_changed_banner_on_the_training_tab
    expect(page.locator("h2", hasText: "Training")).to be_visible
    expect(page.locator(".govuk-notification-banner__content")).to have_text("Contract period changed")
  end

  def and_the_old_training_period_is_finished
    expect(@training_period.reload.finished_on).to eq(Date.current.yesterday)
  end

  def and_a_replacement_training_period_is_created
    replacement_training_period = TrainingPeriod
      .where(ect_at_school_period: @ect_at_school_period)
      .where.not(id: @training_period.id)
      .sole

    expect(replacement_training_period.started_on).to eq(Date.current)
    expect(replacement_training_period.contract_period).to eq(@target_contract_period)
    expect(replacement_training_period.school_partnership).to eq(@target_school_partnership)
    expect(replacement_training_period.schedule).to eq(@target_schedule)
  end

  def and_the_same_future_training_period_is_updated_in_place
    @training_period.reload

    expect(@training_period.id).to eq(@original_training_period_id)
    expect(TrainingPeriod.where(ect_at_school_period: @ect_at_school_period).count).to eq(@original_training_period_count)
    expect(@training_period.schedule).to eq(@target_schedule)
  end

  def and_the_future_training_period_remains_eoi_only
    expect(@training_period.school_partnership).to be_nil
    expect(@training_period.expression_of_interest).to eq(@target_active_lead_provider)
    expect(@training_period.expression_of_interest_contract_period).to eq(@target_contract_period)
  end
end
