RSpec.describe "Admin amending number of terms of an induction period" do
  include ActiveJob::TestHelper

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:teacher) { FactoryBot.create(:teacher) }
  let!(:induction_period) { FactoryBot.create(:induction_period, :active, teacher:, appropriate_body:, number_of_terms: nil) }

  before { sign_in_as_dfe_user(role: :admin) }

  scenario 'Happy path - updating number of terms' do
    given_i_am_on_the_ect_page(teacher)
    then_i_should_see_the_edit_link
    when_i_click_edit_link
    then_i_should_be_on_the_edit_induction_period_page

    when_i_set_end_date("4", "2024")
    when_i_update_the_number_of_terms(5)
    and_i_click_submit

    then_i_should_be_on_the_success_page
    and_the_induction_period_should_have_been_updated
    and_an_event_should_have_been_recorded("Number of terms set to '5.0'")
  end

  scenario 'Validation - cannot enter invalid number of terms' do
    given_i_am_on_the_ect_page(teacher)
    when_i_click_edit_link
    then_i_should_be_on_the_edit_induction_period_page

    when_i_update_the_number_of_terms(-1)
    and_i_click_submit

    then_i_should_see_validation_errors
  end

  scenario 'Cannot edit induction period with outcome' do
    induction_period.update!(outcome: 'pass')

    given_i_am_on_the_ect_page(teacher)
    then_i_should_not_see_the_edit_link
  end

  scenario 'Can edit number of terms when period has outcome' do
    # Set up induction period with an outcome and required number_of_terms
    induction_period.update!(
      outcome: 'pass',
      finished_on: 1.month.ago,
      number_of_terms: 3
    )

    given_i_am_on_the_ect_page(teacher)
    then_i_should_see_the_edit_link
    when_i_click_edit_link
    then_i_should_be_on_the_edit_induction_period_page

    when_i_update_the_number_of_terms(5)
    and_i_click_submit

    then_i_should_be_on_the_success_page
    and_the_induction_period_should_have_been_updated
    and_an_event_should_have_been_recorded("Number of terms changed from '3.0' to '5.0'")
  end

  scenario 'Only number of terms field is shown when period has outcome' do
    induction_period.update!(
      outcome: 'pass',
      finished_on: 1.month.ago,
      number_of_terms: 3 # Add initial number of terms
    )

    given_i_am_on_the_ect_page(teacher)
    then_i_should_see_the_edit_link
    when_i_click_edit_link
    then_i_should_be_on_the_edit_induction_period_page

    then_i_should_see_only_number_of_terms_field
  end

private

  def given_i_am_on_the_ect_page(teacher)
    path = "/admin/teachers/#{teacher.id}"
    page.goto(path)
    expect(page.url).to end_with(path)
  end

  def then_i_should_see_the_edit_link
    expect(page.locator('.govuk-summary-card').get_by_role('link', name: 'Edit')).to be_visible
  end

  def then_i_should_not_see_the_edit_link
    expect(page.locator('.govuk-summary-card').get_by_role('link', name: 'Edit')).not_to be_visible
  end

  def when_i_click_edit_link
    page.locator('.govuk-summary-card').get_by_role('link', name: 'Edit').click
  end

  def then_i_should_be_on_the_edit_induction_period_page
    expect(page.url).to end_with("/admin/teachers/#{teacher.id}/induction-periods/#{induction_period.id}/edit")
  end

  def when_i_set_end_date(month, year)
    end_date_group = page.get_by_role('group', name: 'End date')
    end_date_group.get_by_label('Day').fill("30")
    end_date_group.get_by_label('Month').fill(month)
    end_date_group.get_by_label('Year').fill(year)
  end

  def when_i_update_the_number_of_terms(number)
    page.get_by_label("Number of terms").fill(number.to_s)
  end

  def and_i_click_submit
    page.get_by_role('button', name: "Update").click
  end

  def then_i_should_be_on_the_success_page
    expect(page.url).to end_with("/admin/teachers/#{teacher.id}")
    expect(page.get_by_text('Induction period updated successfully')).to be_visible
  end

  def and_the_induction_period_should_have_been_updated
    induction_period.reload
    expect(induction_period.number_of_terms).to eq(5)
  end

  def and_an_event_should_have_been_recorded(expected_modification)
    perform_enqueued_jobs

    event = Event.last
    expect(event.event_type).to eq("induction_period_updated")
    expect(event.modifications).to include(expected_modification)
  end

  def then_i_should_see_validation_errors
    expect(page.locator('.govuk-error-summary')).to be_visible
    expect(page.get_by_role('alert').get_by_text("Number of terms must be between 0 and 16")).to be_visible
  end

  def when_i_try_to_change_end_date(day, month, year)
    end_date_group = page.get_by_role('group', name: 'End date')
    end_date_group.get_by_label('Day').fill(day)
    end_date_group.get_by_label('Month').fill(month)
    end_date_group.get_by_label('Year').fill(year)
  end

  def then_i_should_see_outcome_error_message
    expect(page.get_by_role('alert')).to have_text("Only number of terms can be edited when outcome is recorded")
  end

  def then_i_should_not_see_end_date_field
    expect(page.get_by_role('group', name: 'End date')).not_to be_visible
  end

  def then_i_should_see_only_number_of_terms_field
    expect(page.get_by_label("Number of terms")).to be_visible
  end
end
