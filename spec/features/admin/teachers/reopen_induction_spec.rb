describe "Admins can reopen a teacher's closed induction" do
  include ActiveJob::TestHelper

  let(:teacher) { FactoryBot.create(:teacher) }

  before do
    FactoryBot.create(:induction_period, :pass, teacher:)
    sign_in_as_dfe_user(role: :admin)
  end

  it "reopens the induction period" do
    when_i_go_to_the_teacher_page
    then_there_is_no_current_induction_period

    when_i_reopen_the_induction
    and_i_do_not_add_any_extra_information
    and_i_am_sure_i_want_to_reopen_the_induction
    then_there_is_an_error_message

    when_i_add_a_zendesk_ticket_id
    and_i_add_a_note("This is a test reason for reopening")
    and_i_am_sure_i_want_to_reopen_the_induction
    and_event_background_jobs_are_executed
    then_the_induction_is_successfully_reopened
    and_there_is_a_current_induction_period

    when_i_go_to_the_timeline_page
    then_i_can_see_the_note("This is a test reason for reopening")
    and_i_can_see_the_zendesk_url
  end

private

  def when_i_go_to_the_teacher_page
    page.goto(admin_teacher_path(teacher))
  end

  def then_there_is_no_current_induction_period
    expect(page.locator("h2", hasText: "Current induction period"))
      .not_to be_visible
  end

  def when_i_reopen_the_induction
    page.get_by_role("link", name: "Reopen induction").click
  end

  def and_i_do_not_add_any_extra_information = nil

  def then_there_is_an_error_message
    expect(page.locator(".govuk-error-summary"))
      .to have_text("There is a problem")
  end

  def when_i_add_a_zendesk_ticket_id
    page.locator("fieldset", hasText: "Explain why you're making this change")
      .get_by_label("Enter the Zendesk ID")
      .fill("123")
  end

  def and_i_add_a_note(reason)
    page.locator("fieldset", hasText: "Explain why you're making this change")
      .get_by_label("Add a note to explain why you're making this change")
      .fill(reason)
  end

  def and_i_am_sure_i_want_to_reopen_the_induction
    expect(page.locator(".govuk-warning-text"))
      .to have_text("Are you sure you want to reopen this induction?")

    page.get_by_role("button", name: "Reopen induction").click
  end

  def and_event_background_jobs_are_executed
    perform_enqueued_jobs(queue: :events)
  end

  def then_the_induction_is_successfully_reopened
    expect(page.locator(".govuk-notification-banner__content"))
      .to have_text("Induction was successfully reopened")
  end

  def and_there_is_a_current_induction_period
    expect(page.locator("h2", hasText: "Current induction period"))
      .to be_visible
  end

  def when_i_go_to_the_timeline_page
    page.goto(admin_teacher_timeline_path(teacher))
  end

  def then_i_can_see_the_note(reason)
    description = page
      .locator(".app-timeline__item", hasText: "Induction period reopened")
      .locator(".app-timeline__description")
    expect(description).to have_text(reason)
  end

  def and_i_can_see_the_zendesk_url
    description = page
      .locator(".app-timeline__item", hasText: "Induction period reopened")
      .locator(".app-timeline__description")
    expect(description.get_by_role("link", name: "Zendesk ticket (opens in new tab)"))
      .to be_visible
  end
end
