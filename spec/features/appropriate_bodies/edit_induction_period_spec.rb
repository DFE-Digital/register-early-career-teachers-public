RSpec.describe "Appropriate body editing an induction period" do
  include ActiveJob::TestHelper

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  # let(:teacher) { FactoryBot.create(:teacher) }
  let(:teacher) { FactoryBot.create(:teacher, trs_qts_awarded_on: 1.year.ago) }

  let!(:induction_period) do
    FactoryBot.create(:induction_period, :active, teacher:, appropriate_body:)
  end

  before do
    sign_in_as_appropriate_body_user(appropriate_body:)
    page.goto(ab_teacher_path(teacher))
  end

  scenario 'valid start date' do
    given_i_am_on_the_teacher_page
    then_i_should_see_the_edit_link
    when_i_click_edit_link
    then_i_should_be_on_the_edit_induction_period_page
    when_i_set_start_date(Time.zone.yesterday)
    and_i_click_submit
    then_i_should_be_on_the_teacher_page
    and_i_should_see_success_banner
  end

  scenario 'invalid start date' do
    given_i_am_on_the_teacher_page
    then_i_should_see_the_edit_link
    when_i_click_edit_link
    then_i_should_be_on_the_edit_induction_period_page
    when_i_set_start_date(2.years.ago)
    and_i_click_submit
    then_i_should_see_an_error('Start date cannot be before QTS award date')
  end

  scenario 'programme type (old)' do
    allow(Rails.application.config).to receive(:enable_bulk_claim).and_return(false)
    given_i_am_on_the_teacher_page
    then_i_should_see_the_edit_link
    when_i_click_edit_link
    then_i_should_be_on_the_edit_induction_period_page

    expect(induction_period.induction_programme).to eq("fip")
    expect(induction_period.training_programme).to eq("provider_led")
    page.get_by_label("Core induction programme").check
    and_i_click_submit

    then_i_should_be_on_the_teacher_page
    and_i_should_see_success_banner

    induction_period.reload
    expect(induction_period.induction_programme).to eq("cip")
    expect(induction_period.training_programme).to eq("school_led")

    and_an_event_should_have_been_recorded(
      "Induction programme changed from 'fip' to 'cip'",
      "Training programme changed from 'provider_led' to 'school_led'"
    )
  end

  scenario 'programme type (new)' do
    allow(Rails.application.config).to receive(:enable_bulk_claim).and_return(true)
    given_i_am_on_the_teacher_page
    then_i_should_see_the_edit_link
    when_i_click_edit_link
    then_i_should_be_on_the_edit_induction_period_page

    expect(induction_period.induction_programme).to eq("fip")
    expect(induction_period.training_programme).to eq("provider_led")
    page.get_by_label("School-led").check
    and_i_click_submit

    then_i_should_be_on_the_teacher_page
    and_i_should_see_success_banner

    induction_period.reload
    expect(induction_period.training_programme).to eq("school_led")
    expect(induction_period.induction_programme).to eq("unknown")

    and_an_event_should_have_been_recorded("Training programme changed from 'provider_led' to 'school_led'")
  end

private

  def given_i_am_on_the_teacher_page
    expect(page.url).to end_with("/appropriate-body/teachers/#{teacher.id}")
  end

  alias_method :then_i_should_be_on_the_teacher_page, :given_i_am_on_the_teacher_page

  def then_i_should_be_on_the_edit_induction_period_page
    expect(page.url).to end_with("/appropriate-body/teachers/#{teacher.id}/induction-periods/#{induction_period.id}/edit")
  end

  def then_i_should_see_the_edit_link
    expect(edit_link).to be_visible
  end

  def when_i_click_edit_link
    edit_link.click
  end

  def when_i_set_start_date(start_date)
    end_date_group = page.get_by_role('group', name: 'Start date')
    end_date_group.get_by_label('Day').fill(start_date.day.to_s)
    end_date_group.get_by_label('Month').fill(start_date.month.to_s)
    end_date_group.get_by_label('Year').fill(start_date.year.to_s)
  end

  def and_i_click_submit
    page.get_by_role('button', name: "Update").click
  end

  def and_i_should_see_success_banner
    expect(page.get_by_text('Induction period updated successfully')).to be_visible
  end

  def and_an_event_should_have_been_recorded(*expected_modification)
    perform_enqueued_jobs

    event = Event.last
    expect(event.event_type).to eq("induction_period_updated")
    expect(event.author_type).to eq("appropriate_body_user")
    expect(event.heading).to eq("Induction period updated by appropriate body")
    expect(event.modifications).to include(*expected_modification)
  end

  def then_i_should_see_an_error(error_message)
    expect(page.locator('.govuk-error-summary')).to be_visible
    expect(page.get_by_role('alert').get_by_text(error_message)).to be_visible
  end

  def edit_link
    page.locator('.govuk-summary-card').get_by_role('link', name: 'Edit')
  end
end
