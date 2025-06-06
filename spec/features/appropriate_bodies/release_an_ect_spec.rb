RSpec.describe 'Releasing an ECT' do
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let!(:induction_period) { FactoryBot.create(:induction_period, :active, teacher:, appropriate_body:) }
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:today) { Time.zone.today }
  let(:number_of_completed_terms) { 4 }

  before { sign_in_as_appropriate_body_user(appropriate_body:) }

  scenario 'Happy path' do
    given_i_am_on_the_ect_page(teacher)
    when_i_click_link('Release')
    then_i_should_be_on_the_release_ect_page(teacher)

    when_i_submit_the_form_without_filling_anything_in
    then_i_should_see_an_error_summary
    and_the_page_title_should_start_with_error

    when_i_enter_the_finish_date
    and_i_enter_a_terms_value_of(number_of_completed_terms)
    and_i_click_continue

    then_i_should_be_on_the_success_page
    and_the_release_ect_service_should_have_been_called
    and_the_pending_induction_submission_delete_at_timestamp_is_set
  end

private

  def given_i_am_on_the_ect_page(teacher)
    path = "/appropriate-body/teachers/#{teacher.id}"
    page.goto(path)
    expect(page.url).to end_with(path)
  end

  def when_i_click_link(text)
    page.get_by_role('link', name: text).click
  end

  def then_i_should_be_on_the_release_ect_page(teacher)
    expect(page.url).to end_with("/appropriate-body/teachers/#{teacher.id}/release/new")
  end

  def when_i_submit_the_form_without_filling_anything_in
    and_i_click_continue
  end

  def then_i_should_see_an_error_summary
    expect(page.locator('.govuk-error-summary')).to be_visible
  end

  def and_the_page_title_should_start_with_error
    expect(page.title).to start_with('Error:')
  end

  def when_i_enter_the_finish_date
    page.get_by_label('Day').fill(today.day.to_s)
    page.get_by_label('Month').fill(today.month.to_s)
    page.get_by_label('Year').fill(today.year.to_s)
  end

  def and_i_enter_a_terms_value_of(number)
    label = /How many terms/

    page.get_by_label(label).fill(number.to_s)
  end

  def and_i_click_continue
    page.get_by_role('button', name: 'Continue').click
  end

  def then_i_should_be_on_the_success_page
    expect(page.url).to end_with("/appropriate-body/teachers/#{teacher.id}/release")
    expect(page.locator('.govuk-panel')).to be_visible

    teacher_name = ::Teachers::Name.new(teacher).full_name

    expect(page.locator('.govuk-panel')).to have_text(/You've successfully released #{teacher_name}/)
  end

  def and_the_pending_induction_submission_delete_at_timestamp_is_set
    expect(PendingInductionSubmission.find_by(trn: teacher.trn, appropriate_body:).delete_at).to be_within(1.second).of(24.hours.from_now)
  end

  def and_the_release_ect_service_should_have_been_called
    induction_period.reload
    expect(induction_period.number_of_terms).to eq(number_of_completed_terms)
    expect(induction_period.finished_on).to eql(today)
  end
end
