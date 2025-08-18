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
    and_i_add_a_support_ticket_url("https://example.com/ticket/123")
    and_i_add_a_note("This is a test reason for reopening")
    and_i_am_sure_i_want_to_reopen_the_induction
    and_event_background_jobs_are_executed
    then_the_induction_is_successfully_reopened
    and_there_is_a_current_induction_period

    when_i_go_to_the_timeline_page
    then_i_can_see_the_note("This is a test reason for reopening")
    and_i_can_see_the_support_ticket_url("https://example.com/ticket/123")
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

  def and_i_add_a_support_ticket_url(url)
    page.locator("fieldset", hasText: "Explain why you're making this update")
      .get_by_label("Add a Zendesk or Trello link")
      .fill(url)
  end

  def and_i_add_a_note(reason)
    page.locator("fieldset", hasText: "Explain why you're making this update")
      .get_by_label("Add a written note")
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

  def and_i_can_see_the_support_ticket_url(url)
    description = page
      .locator(".app-timeline__item", hasText: "Induction period reopened")
      .locator(".app-timeline__description")
    expect(description).to have_text("Support ticket: #{url}")
  end
end
