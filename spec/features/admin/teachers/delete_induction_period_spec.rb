RSpec.describe "Admin deletes an induction period" do
  include ActiveJob::TestHelper

  include_context "test trs api client"

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:teacher) { FactoryBot.create(:teacher) }

  before do
    sign_in_as_dfe_user(role: :admin)
  end

  context "when it is the only induction period" do
    let!(:induction_period) { FactoryBot.create(:induction_period, :ongoing, teacher:, appropriate_body:, started_on: Date.new(2020, 1, 1), finished_on: Date.new(2020, 12, 31), number_of_terms: 2) }

    context "and a ticket and reason are provided" do
      it "deletes the induction, resets TRS, adds context to the timeline" do
        given_i_am_on_the_teacher_page
        then_i_should_see_the_delete_link
        when_i_click_delete_link
        then_i_should_see_the_delete_confirmation_page

        when_i_do_not_add_any_extra_information
        and_i_confirm_deletion
        then_there_is_an_error_message

        when_i_add_a_zendesk_ticket_id("#123456")
        and_i_add_a_note("This is a test reason for deleting")
        and_i_confirm_deletion
        then_i_should_be_on_the_success_page
        and_the_induction_period_should_be_deleted(induction_period)
        and_an_event_should_have_been_recorded
        and_trs_status_should_be_reset

        when_i_go_to_the_timeline_page
        then_i_can_see_the_note("This is a test reason for deleting")
        and_i_can_see_the_zendesk_link("https://becomingateacher.zendesk.com/agent/tickets/123456")
      end
    end

    context "and no reason is provided" do
      it "deletes the induction, resets TRS, adds context to the timeline" do
        given_i_am_on_the_teacher_page
        then_i_should_see_the_delete_link
        when_i_click_delete_link
        then_i_should_see_the_delete_confirmation_page
        when_i_add_a_zendesk_ticket_id("123456")
        and_i_confirm_deletion
        then_i_should_be_on_the_success_page
        and_the_induction_period_should_be_deleted(induction_period)
        and_an_event_should_have_been_recorded
        and_trs_status_should_be_reset

        when_i_go_to_the_timeline_page
        and_i_can_see_the_zendesk_link("https://becomingateacher.zendesk.com/agent/tickets/123456")
      end
    end

    context 'and the zendesk ticket is invalid' do
      it "shows an error message" do
        given_i_am_on_the_teacher_page
        then_i_should_see_the_delete_link
        when_i_click_delete_link
        then_i_should_see_the_delete_confirmation_page
        when_i_add_a_zendesk_ticket_id("123")
        and_i_confirm_deletion
        then_there_is_an_error_message
      end
    end
  end

  context "when there are multiple induction periods" do
    let!(:induction_period1) { FactoryBot.create(:induction_period, :ongoing, teacher:, appropriate_body:, started_on: Date.new(2020, 1, 1), finished_on: Date.new(2020, 12, 31), number_of_terms: 2) }
    let!(:induction_period2) { FactoryBot.create(:induction_period, :ongoing, teacher:, appropriate_body:, started_on: Date.new(2021, 1, 1), finished_on: Date.new(2021, 12, 31), number_of_terms: 2) }

    scenario "TRS start date is updated to next earliest period" do
      given_i_am_on_the_teacher_page
      then_i_should_see_the_delete_link_for(induction_period1)
      when_i_click_delete_link_for(induction_period1)
      then_i_should_see_the_delete_confirmation_page
      when_i_add_a_zendesk_ticket_id("#123456")
      and_i_add_a_note("This is a test reason for deleting")
      and_i_confirm_deletion
      then_i_should_be_on_the_success_page
      and_the_induction_period_should_be_deleted(induction_period1)
      and_an_event_should_have_been_recorded
      and_trs_status_should_not_be_reset

      when_i_go_to_the_timeline_page
      then_i_can_see_the_note("This is a test reason for deleting")
      and_i_can_see_the_zendesk_link("https://becomingateacher.zendesk.com/agent/tickets/123456")
    end
  end

  context "when deleting the later induction period" do
    let!(:induction_period1) { FactoryBot.create(:induction_period, :ongoing, teacher:, appropriate_body:, started_on: Date.new(2020, 1, 1), finished_on: Date.new(2020, 12, 31), number_of_terms: 2) }
    let!(:induction_period2) { FactoryBot.create(:induction_period, :ongoing, teacher:, appropriate_body:, started_on: Date.new(2021, 1, 1), finished_on: Date.new(2021, 12, 31), number_of_terms: 2) }

    scenario "TRS start date remains unchanged" do
      given_i_am_on_the_teacher_page
      then_i_should_see_the_delete_link_for(induction_period2)
      when_i_click_delete_link_for(induction_period2)
      then_i_should_see_the_delete_confirmation_page

      when_i_do_not_add_any_extra_information
      and_i_confirm_deletion
      then_there_is_an_error_message

      when_i_add_a_zendesk_ticket_id("#123456")
      and_i_add_a_note("This is a test reason for deleting")
      and_i_confirm_deletion
      then_i_should_be_on_the_success_page
      and_the_induction_period_should_be_deleted(induction_period2)
      and_an_event_should_have_been_recorded
      and_trs_status_should_not_be_reset

      when_i_go_to_the_timeline_page
      then_i_can_see_the_note("This is a test reason for deleting")
      and_i_can_see_the_zendesk_link("https://becomingateacher.zendesk.com/agent/tickets/123456")
    end
  end

private

  def given_i_am_on_the_teacher_page
    page.goto(admin_teacher_path(teacher))
  end

  def then_i_should_see_the_delete_link
    expect(page.locator('.govuk-summary-card').get_by_role('link', name: 'Delete')).to be_visible
  end

  def then_i_should_see_the_delete_link_for(period)
    expect(page.locator("xpath=//div[contains(@class,'govuk-summary-card')][.//dd[text()='#{period.started_on.to_fs(:govuk)}']]//a[text()='Delete']")).to be_visible
  end

  def when_i_click_delete_link
    page.locator('.govuk-summary-card').get_by_role('link', name: 'Delete').click
  end

  def when_i_click_delete_link_for(period)
    page.locator("xpath=//div[contains(@class,'govuk-summary-card')][.//dd[text()='#{period.started_on.to_fs(:govuk)}']]//a[text()='Delete']").click
  end

  def then_i_should_see_the_delete_confirmation_page
    expect(page.get_by_text('Are you sure you want to delete this induction period?')).to be_visible
    expect(page.get_by_role('button', name: 'Delete induction period')).to be_visible
  end

  def when_i_do_not_add_any_extra_information = nil

  def then_there_is_an_error_message
    expect(page.locator(".govuk-error-summary"))
      .to have_text("There is a problem")
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

  def and_i_confirm_deletion
    perform_enqueued_jobs do
      page.get_by_role('button', name: 'Delete induction period').click
    end
  end

  def then_i_should_be_on_the_success_page
    expect(page.get_by_text('Induction period deleted successfully')).to be_visible
  end

  def and_the_induction_period_should_be_deleted(period)
    expect(InductionPeriod.exists?(id: period.id)).to be false
  end

  def and_an_event_should_have_been_recorded
    event = Event.where(event_type: 'induction_period_deleted').last
    expect(event.event_type).to eq('induction_period_deleted')
    expect(event.author_type).to eq('dfe_staff_user')
    expect(event.heading).to eq('Induction period deleted by admin')
    expect(event.teacher).to eq(teacher)
  end

  def and_trs_status_should_be_reset
    expect(page).not_to have_selector('.govuk-summary-card')
  end

  def and_trs_status_should_not_be_reset
    expect(teacher.induction_periods.count).to eq(1)
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
    expect(link).to have_attribute('href', url)
    expect(link).to have_attribute('target', '_blank')
  end

  alias_method :and_i_can_see_the_zendesk_link, :then_i_can_see_the_zendesk_link

  def timeline_milestone
    "Induction period deleted"
  end
end
