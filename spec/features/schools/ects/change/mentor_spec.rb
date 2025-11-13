describe "School user can change early career teachers mentor", :enable_schools_interface do
  before do
    given_there_is_a_school
    and_there_is_a_mentee
    and_i_am_logged_in_as_a_school_user
  end

  context "when the mentor does not need mentor training" do
    it "changes the mentor to an existing mentor" do
      and_the_mentee_is_on_school_led_training
      and_the_mentee_has_an_assigned_mentor
      and_there_is_another_registered_mentor

      when_i_visit_the_early_career_teacher_show_page
      then_i_can_change_the_assigned_mentor
      and_i_see_the_change_mentor_form
      and_the_current_mentor_is_not_an_option

      when_i_change_the_mentor_to_another_registered_mentor
      and_i_click_continue
      then_i_am_asked_to_check_and_confirm_the_change

      when_i_click_the_back_link
      and_i_see_the_change_mentor_form
      then_the_mentor_is_selected

      when_i_click_continue
      and_i_confirm_the_change
      then_i_see_the_confirmation_message
    end
  end

  context "when the mentor can receive mentor training" do
    it "changes the mentor to an existing mentor with the same lead provider" do
      and_there_is_a_contract_period
      with_provider_led_training
      and_the_mentee_has_an_assigned_mentor
      and_there_is_another_registered_mentor
      and_the_other_registered_mentor_can_receive_mentor_training

      when_i_visit_the_early_career_teacher_show_page
      then_i_can_change_the_assigned_mentor
      and_i_see_the_change_mentor_form
      and_the_current_mentor_is_not_an_option

      when_i_change_the_mentor_to_another_registered_mentor
      and_i_click_continue
      then_the_mentor_can_receive_mentor_training

      when_i_click_the_back_link
      and_i_see_the_change_mentor_form
      then_the_mentor_is_selected

      when_i_click_continue
      and_i_click_continue
      then_i_am_asked_to_check_and_confirm_the_change

      when_i_click_the_back_link
      then_the_mentor_can_receive_mentor_training

      when_i_click_continue
      and_i_confirm_the_change
      then_i_see_the_confirmation_message
    end

    it "changes the mentor to an existing mentor with a different lead provider" do
      and_there_is_a_contract_period
      and_there_is_an_active_lead_provider
      with_provider_led_training
      and_the_mentee_has_an_assigned_mentor
      and_there_is_another_registered_mentor
      and_the_other_registered_mentor_can_receive_mentor_training

      when_i_visit_the_early_career_teacher_show_page
      then_i_can_change_the_assigned_mentor
      and_i_see_the_change_mentor_form
      and_the_current_mentor_is_not_an_option

      when_i_change_the_mentor_to_another_registered_mentor
      and_i_click_continue
      then_the_mentor_can_receive_mentor_training

      when_i_click_the_back_link
      and_i_see_the_change_mentor_form
      then_the_mentor_is_selected

      when_i_click_continue
      then_i_change_lead_provider
      and_i_see_the_change_lead_provider_form

      when_i_choose_a_lead_provider
      and_i_click_continue
      then_i_am_asked_to_check_and_confirm_the_change

      when_i_click_the_back_link
      and_i_see_the_change_lead_provider_form
      then_the_lead_provider_is_selected

      when_i_click_continue
      and_i_confirm_the_change
      then_i_see_the_confirmation_message
    end
  end

  context "when the mentor needs to be registered" do
    it "directs the user to the register mentor wizard for this mentee" do
      and_the_mentee_is_on_school_led_training
      and_the_mentee_has_an_assigned_mentor
      and_there_is_another_registered_mentor

      when_i_visit_the_early_career_teacher_show_page
      then_i_can_change_the_assigned_mentor
      and_i_see_the_change_mentor_form
      and_the_current_mentor_is_not_an_option

      when_i_change_the_mentor_to_a_new_mentor
      and_i_click_continue
      then_i_am_redirected_to_the_register_new_mentor_wizard_for_this_mentee

      when_i_click_the_back_link
      and_i_see_the_change_mentor_form
      then_the_register_new_mentor_radio_is_selected
    end
  end

private

  def given_there_is_a_school
    @school = FactoryBot.create(:school)
  end

  def and_there_is_a_mentee
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
      started_on: 1.week.ago
    )
  end

  def and_there_is_a_contract_period
    @contract_period = FactoryBot.create(:contract_period, :with_schedules, :current)
  end

  def and_there_is_an_active_lead_provider
    lead_provider = FactoryBot.create(:lead_provider, name: "Testing Provider")
    @active_lead_provider = FactoryBot.create(
      :active_lead_provider,
      contract_period: @contract_period,
      lead_provider:
    )
  end

  def and_the_mentee_is_on_school_led_training
    FactoryBot.create(
      :training_period,
      :school_led,
      :for_ect,
      :ongoing,
      ect_at_school_period: @ect_at_school_period,
      started_on: @ect_at_school_period.started_on
    )
  end

  def with_provider_led_training
    @provider_led_training_period = FactoryBot.create(
      :training_period,
      :provider_led,
      :for_ect,
      :ongoing,
      ect_at_school_period: @ect_at_school_period,
      started_on: @ect_at_school_period.started_on
    )
    @provider_led_training_period
      .active_lead_provider
      .update!(contract_period: @contract_period)
  end

  def and_the_mentee_has_an_assigned_mentor
    teacher = FactoryBot.create(
      :teacher,
      trs_first_name: "John",
      trs_last_name: "Mentor"
    )
    mentor_at_school_period = FactoryBot.create(
      :mentor_at_school_period,
      :ongoing,
      teacher:,
      school: @school,
      started_on: @ect_at_school_period.started_on - 2.months
    )
    FactoryBot.create(
      :mentorship_period,
      :ongoing,
      mentee: @ect_at_school_period,
      mentor: mentor_at_school_period,
      started_on: @ect_at_school_period.started_on
    )
  end

  def and_there_is_another_registered_mentor
    @mentor_teacher = FactoryBot.create(
      :teacher,
      trs_first_name: "Jane",
      trs_last_name: "Smith"
    )
    FactoryBot.create(
      :mentor_at_school_period,
      :ongoing,
      teacher: @mentor_teacher,
      school: @school,
      started_on: @ect_at_school_period.started_on - 1.month
    )
  end

  def and_the_other_registered_mentor_can_receive_mentor_training
    @mentor_teacher.update!(
      mentor_became_ineligible_for_funding_on: nil,
      mentor_became_ineligible_for_funding_reason: nil
    )
  end

  def and_i_am_logged_in_as_a_school_user
    sign_in_as_school_user(school: @school)
  end

  def when_i_visit_the_early_career_teacher_show_page
    page.goto(schools_ect_path(@ect_at_school_period))
  end

  def then_i_can_change_the_assigned_mentor
    row = page.locator(".govuk-summary-list__row", hasText: "Mentor")
    row.get_by_role("link", name: "Change").click
  end

  def and_i_see_the_change_mentor_form
    heading = page.locator("h1")
    expect(heading).to have_text("Who will mentor John Doe?")
  end

  def and_the_current_mentor_is_not_an_option
    expect(page.get_by_label("John Mentor")).not_to be_visible
  end

  def when_i_change_the_mentor_to_another_registered_mentor
    page.get_by_label("Jane Smith").check
  end

  def then_the_mentor_can_receive_mentor_training
    heading = page.locator("h1")
    expect(heading).to have_text("Jane Smith can receive mentor training")
  end

  def then_i_am_asked_to_check_and_confirm_the_change
    heading = page.locator("h1")
    expect(heading).to have_text("Check and confirm change")
  end

  def then_the_mentor_is_selected
    mentor_radio = page.get_by_label("Jane Smith")
    expect(mentor_radio).to be_checked
  end

  def then_the_register_new_mentor_radio_is_selected
    mentor_radio = page.get_by_label("Register a new mentor")
    expect(mentor_radio).to be_checked
  end

  def and_i_confirm_the_change
    page.get_by_role("button", name: "Confirm change").click
  end

  def then_i_change_lead_provider
    change_provider_link_text = <<~TXT.squish
      #{@provider_led_training_period.lead_provider.name} will not be providing
      mentor training to Jane Smith
    TXT
    page.get_by_role("link", name: change_provider_link_text).click
  end

  def and_i_see_the_change_lead_provider_form
    heading = page.locator("h1")
    expect(heading).to have_text("Which lead provider would you like to contact")
  end

  def when_i_choose_a_lead_provider
    page.get_by_label("Testing Provider").check
  end

  def then_the_lead_provider_is_selected
    lead_provider_radio = page.get_by_label("Testing Provider")
    expect(lead_provider_radio).to be_checked
  end

  def then_i_see_the_confirmation_message
    success_panel = page.locator(".govuk-panel")
    expect(success_panel).to have_text(
      "You have changed John Doe’s mentor to Jane Smith"
    )
  end

  def when_i_change_the_mentor_to_a_new_mentor
    page.get_by_label("Register a new mentor").check
  end

  def then_i_am_redirected_to_the_register_new_mentor_wizard_for_this_mentee
    heading = page.locator("h1")
    expect(heading).to have_text("What you'll need to add a new mentor for John Doe")
  end
end
