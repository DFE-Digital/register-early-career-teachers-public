RSpec.describe "Admin deletes an induction period" do
  include ActiveJob::TestHelper

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:teacher) { FactoryBot.create(:teacher) }

  before { sign_in_as_dfe_user(role: :admin) }

  context "when it is the only induction period" do
    let!(:induction_period) { FactoryBot.create(:induction_period, :active, teacher:, appropriate_body:, started_on: Date.new(2020, 1, 1), finished_on: Date.new(2020, 12, 31), number_of_terms: 2) }

    scenario "TRS status is reset" do
      given_i_am_on_the_ect_page(teacher)
      then_i_should_see_the_delete_link
      when_i_click_delete_link
      then_i_should_see_the_delete_confirmation_page

      when_i_confirm_deletion
      then_i_should_be_on_the_success_page
      and_the_induction_period_should_be_deleted(induction_period)
      and_an_event_should_have_been_recorded
      and_trs_status_should_be_reset
    end
  end

  context "when there are multiple induction periods" do
    let!(:induction_period1) { FactoryBot.create(:induction_period, :active, teacher:, appropriate_body:, started_on: Date.new(2020, 1, 1), finished_on: Date.new(2020, 12, 31), number_of_terms: 2) }
    let!(:induction_period2) { FactoryBot.create(:induction_period, :active, teacher:, appropriate_body:, started_on: Date.new(2021, 1, 1), finished_on: Date.new(2021, 12, 31), number_of_terms: 2) }

    scenario "TRS status is not reset" do
      given_i_am_on_the_ect_page(teacher)
      then_i_should_see_the_delete_link_for(induction_period1)
      when_i_click_delete_link_for(induction_period1)
      then_i_should_see_the_delete_confirmation_page

      when_i_confirm_deletion
      then_i_should_be_on_the_success_page
      and_the_induction_period_should_be_deleted(induction_period1)
      and_an_event_should_have_been_recorded
      and_trs_status_should_not_be_reset
    end
  end

  def given_i_am_on_the_ect_page(teacher)
    path = "/admin/teachers/#{teacher.id}"
    page.goto(path)
    expect(page.url).to end_with(path)
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

  def when_i_confirm_deletion
    perform_enqueued_jobs do
      page.get_by_role('button', name: 'Delete induction period').click
    end
  end

  def then_i_should_be_on_the_success_page
    expect(page.url).to match(%r{/admin/teachers/\d+$})
    expect(page.get_by_text('Induction period deleted successfully')).to be_visible
  end

  def and_the_induction_period_should_be_deleted(period)
    expect(InductionPeriod.exists?(id: period.id)).to be false
  end

  def and_an_event_should_have_been_recorded
    event = Event.last
    expect(event.event_type).to eq("induction_period_deleted")
    expect(event.teacher).to eq(teacher)
  end

  def and_trs_status_should_be_reset
    expect(page).not_to have_selector('.govuk-summary-card')
  end

  def and_trs_status_should_not_be_reset
    expect(teacher.induction_periods.count).to eq(1)
  end
end
