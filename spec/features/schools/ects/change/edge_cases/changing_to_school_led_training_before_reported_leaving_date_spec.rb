RSpec.describe "Changing to school-led training before the ECTs reported leaving date", :enable_schools_interface do
  include ChangesBeforeReportedLeavingDateHelpers

  include_context "test TRS API returns a teacher"

  before do
    freeze_time
    given_there_is_a_school
    and_there_is_an_ect_at_the_school
    and_the_ect_is_doing_provider_led_training
    and_there_is_another_school
  end

  context "when changing to school-led training " \
          "before transfer date " \
          "after being reported as leaving" do
    before do
      given_i_am_logged_in_as_a_school_user(@school)
      @leaving_date = @ect_at_school_period.started_on.advance(months: 6)
      and_i_report_the_ect_as_leaving(on: @leaving_date)
    end

    it "allows the change and creates training periods with the correct dates" do
      when_i_visit_the_ect_page
      then_i_can_change_the_training_programme
      and_i_can_change_the_training_programme_to_school_led

      when_i_change_the_training_programme
      then_i_am_asked_to_check_and_confirm_the_change

      when_i_confirm_the_change
      then_i_see_the_school_led_confirmation_message

      given_i_am_logged_in_as_an_admin
      when_i_visit_the_admin_teacher_school_page
      then_i_see_the_correct_ect_at_school_periods(
        { school: @school, start: @ect_at_school_period.started_on, end: @leaving_date }
      )

      when_i_visit_the_admin_teacher_training_page
      then_i_see_the_correct_training_periods(
        { school: @school, type: "School-led", start: Date.current, end: @leaving_date },
        { school: @school, type: "Provider-led", lead_provider: @lead_provider, start: @ect_at_school_period.started_on, end: Date.current }
      )
    end
  end

  context "when changing to school-led training " \
          "before transfer date " \
          "after being reported as joining by another school" do
    before do
      @joining_date = @ect_at_school_period.started_on.advance(months: 6)
      given_the_ect_has_been_registered_by_another_school(on: @joining_date)
      and_i_am_logged_in_as_a_school_user(@school)
    end

    it "allows the change and creates training periods with the correct dates" do
      when_i_visit_the_ect_page
      then_i_can_change_the_training_programme
      and_i_can_change_the_training_programme_to_school_led

      when_i_change_the_training_programme
      then_i_am_asked_to_check_and_confirm_the_change

      when_i_confirm_the_change
      then_i_see_the_school_led_confirmation_message

      given_i_am_logged_in_as_an_admin
      when_i_visit_the_admin_teacher_school_page
      then_i_see_the_correct_ect_at_school_periods(
        { school: @another_school, start: @joining_date, end: nil },
        { school: @school, start: @ect_at_school_period.started_on, end: @joining_date.yesterday }
      )

      when_i_visit_the_admin_teacher_training_page
      then_i_see_the_correct_training_periods(
        { school: @another_school, type: "School-led", start: @joining_date, end: nil },
        { school: @school, type: "School-led", start: Date.current, end: @joining_date.yesterday },
        { school: @school, type: "Provider-led", lead_provider: @lead_provider, start: @ect_at_school_period.started_on, end: Date.current }
      )
    end
  end

  context "when changing to school-led training " \
          "before transfer date " \
          "after being reported as leaving " \
          "and later reported as joining on a different date" do
    before do
      given_i_am_logged_in_as_a_school_user(@school)
      @leaving_date = @ect_at_school_period.started_on.advance(months: 6)
      and_i_report_the_ect_as_leaving(on: @leaving_date)
    end

    it "allows the change and creates training periods with the correct dates" do
      when_i_visit_the_ect_page
      then_i_can_change_the_training_programme
      and_i_can_change_the_training_programme_to_school_led

      when_i_change_the_training_programme
      then_i_am_asked_to_check_and_confirm_the_change

      when_i_confirm_the_change
      then_i_see_the_school_led_confirmation_message

      @joining_date = @leaving_date.advance(weeks: -2)
      given_the_ect_has_been_registered_by_another_school(on: @joining_date)

      given_i_am_logged_in_as_an_admin
      when_i_visit_the_admin_teacher_school_page
      then_i_see_the_correct_ect_at_school_periods(
        { school: @another_school, start: @joining_date, end: nil },
        { school: @school, start: @ect_at_school_period.started_on, end: @joining_date.yesterday }
      )

      when_i_visit_the_admin_teacher_training_page
      then_i_see_the_correct_training_periods(
        { school: @another_school, type: "School-led", start: @joining_date, end: nil },
        { school: @school, type: "School-led", start: Date.current, end: @joining_date.yesterday },
        { school: @school, type: "Provider-led", lead_provider: @lead_provider, start: @ect_at_school_period.started_on, end: Date.current }
      )
    end
  end

private

  def and_the_ect_is_doing_provider_led_training
    contract_period = FactoryBot.create(:contract_period, :current)
    active_lead_provider = FactoryBot.create(:active_lead_provider, contract_period:)
    FactoryBot.create(
      :training_period,
      :for_ect,
      :ongoing,
      :provider_led,
      :with_active_lead_provider,
      ect_at_school_period: @ect_at_school_period,
      active_lead_provider:
    )
    @lead_provider = active_lead_provider.lead_provider
  end

  def then_i_can_change_the_training_programme
    row = page.locator(".govuk-summary-list__row", hasText: "Training programme")
    row.get_by_role("link", name: "Change").click
  end

  def and_i_can_change_the_training_programme_to_school_led
    heading = page.locator("h1", hasText: "Change Mr Teacher’s training programme to school-led")
    expect(heading).to be_visible
  end

  def when_i_change_the_training_programme
    page.get_by_role("button", name: "Change training programme").click
  end

  def then_i_see_the_school_led_confirmation_message
    school_led_message = "You’ve changed Mr Teacher’s training programme to school-led"
    then_panel_is_visible_with(message: school_led_message)
  end

  def when_i_visit_the_admin_teacher_training_page
    page.goto(admin_teacher_training_path(@ect_at_school_period.teacher))
  end
end
