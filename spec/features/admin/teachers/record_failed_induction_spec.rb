RSpec.describe "Admin recording a failed induction" do
  include ActiveJob::TestHelper

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let!(:induction_period) { FactoryBot.create(:induction_period, :ongoing, teacher:, appropriate_body:) }
  let(:teacher) { FactoryBot.create(:teacher, :with_name) }
  let(:today) { Time.zone.today }

  before { sign_in_as_dfe_user(role: :admin) }

  context "with a ticket and reason" do
    it "fails the induction period and adds context to the timeline" do
      given_i_am_on_the_teacher_induction_page
      when_i_click_link("Fail induction")
      then_i_should_be_on_the_record_outcome_page

      when_i_enter_the_finish_date
      when_i_enter_the_written_fail_confirmation_on_date
      and_i_enter_a_terms_value_of("3.5")

      when_i_add_a_zendesk_ticket_id("#123456")
      and_i_add_a_note("This is a test reason for failing the induction")

      and_i_click_submit
      and_event_background_jobs_are_executed

      then_i_should_be_on_the_success_page
      and_the_induction_is_failed

      when_i_go_to_the_timeline_page
      then_i_can_see_the_note("This is a test reason for failing the induction")
      and_i_can_see_the_zendesk_link("https://becomingateacher.zendesk.com/agent/tickets/123456")
    end
  end

  context "without a ticket and reason" do
    it "raises a validation error" do
      given_i_am_on_the_teacher_induction_page
      when_i_click_link("Fail induction")
      then_i_should_be_on_the_record_outcome_page

      when_i_enter_the_finish_date
      and_i_enter_a_terms_value_of("3.5")

      and_i_click_submit

      then_there_is_an_error_message
    end
  end

private

  def given_i_am_on_the_teacher_induction_page
    page.goto(admin_teacher_induction_path(teacher))
  end

  def when_i_click_link(text)
    page.get_by_role("link", name: text).click
  end

  def then_i_should_be_on_the_record_outcome_page
    expect(page).to have_path("/admin/teachers/#{teacher.id}/record-failed-outcome/new")
  end

  def when_i_enter_the_finish_date
    page.fill "#admin_record_fail_finished_on_3i", today.day.to_s
    page.fill "#admin_record_fail_finished_on_2i", today.month.to_s
    page.fill "#admin_record_fail_finished_on_1i", today.year.to_s
  end

  def when_i_enter_the_written_fail_confirmation_on_date
    page.fill "#admin_record_fail_written_fail_confirmation_on_3i", today.day.to_s
    page.fill "#admin_record_fail_written_fail_confirmation_on_2i", today.month.to_s
    page.fill "#admin_record_fail_written_fail_confirmation_on_1i", today.year.to_s
  end

  def and_i_enter_a_terms_value_of(number_of_terms)
    page.get_by_label("How many terms of induction did they complete?").fill(number_of_terms)
  end

  def and_i_click_submit
    page.get_by_role("button", name: "Record failing outcome for John Keating").click
  end

  def then_there_is_an_error_message
    expect(page.locator(".govuk-error-summary")).to have_text("There is a problem")
  end

  def then_i_should_be_on_the_success_page
    expect(page).to have_path("/admin/teachers/#{teacher.id}/record-failed-outcome")
    expect(page.locator(".govuk-panel__title")).to have_text("Outcome recorded")
    expect(page.locator(".govuk-panel__body")).to have_text("John Keating has failed their induction")
  end

  def and_the_induction_is_failed
    induction_period.reload
    expect(induction_period.outcome).to eql("fail")
    expect(induction_period.number_of_terms).to eq(3.5)
    expect(induction_period.finished_on).to eql(today)
  end

  def and_event_background_jobs_are_executed
    perform_enqueued_jobs(queue: :events)
  end

  def when_i_add_a_zendesk_ticket_id(ticket)
    page.locator("fieldset", hasText: "Explain why you're making this change")
      .get_by_label("Enter Zendesk ticket number")
      .fill(ticket)
  end

  def and_i_add_a_note(reason)
    page.locator("fieldset", hasText: "Explain why you're making this change")
      .get_by_label("Add a note to explain why you're making this change")
      .fill(reason)
  end

  def when_i_go_to_the_timeline_page
    page.goto(admin_teacher_timeline_path(teacher))
  end

  def then_i_can_see_the_note(reason)
    description = page
      .locator(".app-timeline__item", hasText: timeline_milestone)
      .locator(".app-timeline__description")
    expect(description).to have_text(reason)
  end

  def then_i_can_see_the_zendesk_link(url)
    description = page
      .locator(".app-timeline__item", hasText: timeline_milestone)
      .locator(".app-timeline__description")
    link = description.get_by_role("link", name: "Zendesk ticket (opens in new tab)")
    expect(link).to be_visible
    expect(link).to have_attribute("href", url)
    expect(link).to have_attribute("target", "_blank")
  end

  alias_method :and_i_can_see_the_zendesk_link, :then_i_can_see_the_zendesk_link

  def timeline_milestone
    "John Keating failed induction by admin"
  end
end
