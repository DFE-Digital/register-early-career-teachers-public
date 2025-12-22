RSpec.describe "Recording a failed outcome for an ECT" do
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let!(:induction_period) { FactoryBot.create(:induction_period, :ongoing, teacher:, appropriate_body:) }
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:today) { Time.zone.today }
  let(:number_of_completed_terms) { 4 }

  before { sign_in_as_appropriate_body_user(appropriate_body:) }

  scenario "Happy path" do
    given_i_am_on_the_ect_page(teacher)
    when_i_click_link("Fail induction")
    then_i_should_be_on_the_fail_confimation_page(teacher)

    when_i_confirm_written_confirmation_sent
    and_i_click_continue_button
    then_i_should_be_on_the_record_outcome_page(teacher)

    when_i_enter_the_finish_date
    when_i_enter_the_fail_confirmation_sent_on_date
    and_i_enter_a_terms_value_of(number_of_completed_terms)
    and_i_click_submit

    then_i_should_be_on_the_success_page
    and_the_pending_induction_submission_record_should_have_the_right_data_in_it
    and_the_induction_period_should_have_been_closed_with_the_right_data
  end

private

  def given_i_am_on_the_ect_page(teacher)
    path = "/appropriate-body/teachers/#{teacher.id}"
    page.goto(path)

    expect(page).to have_path(path)
  end

  def when_i_click_link(text)
    page.get_by_role("link", name: text).click
  end

  def then_i_should_be_on_the_fail_confimation_page(teacher)
    expect(page).to have_path("/appropriate-body/teachers/#{teacher.id}/record-failed-outcome/confirmation")
  end

  def when_i_confirm_written_confirmation_sent
    page.click("#teacher-confirm-failed-outcome-1-field")
  end

  def and_i_click_continue_button
    page.click(".govuk-button")
  end

  def then_i_should_be_on_the_record_outcome_page(teacher)
    expect(page).to have_path("/appropriate-body/teachers/#{teacher.id}/record-failed-outcome/new")
  end

  def when_i_enter_the_finish_date
    page.fill "#appropriate_bodies_record_fail_finished_on_3i", today.day.to_s
    page.fill "#appropriate_bodies_record_fail_finished_on_2i", today.month.to_s
    page.fill "#appropriate_bodies_record_fail_finished_on_1i", today.year.to_s
  end

  def when_i_enter_the_fail_confirmation_sent_on_date
    page.fill "#appropriate_bodies_record_fail_fail_confirmation_sent_on_3i", today.day.to_s
    page.fill "#appropriate_bodies_record_fail_fail_confirmation_sent_on_2i", today.month.to_s
    page.fill "#appropriate_bodies_record_fail_fail_confirmation_sent_on_1i", today.year.to_s
  end

  def and_i_enter_a_terms_value_of(number)
    label = "How many terms of induction did they spend with you?"

    page.get_by_label(label).fill(number.to_s)
  end

  def and_i_click_submit
    teacher_name = Teachers::Name.new(teacher).full_name
    page.get_by_role("button", name: "Record failing outcome for #{teacher_name}").click
  end

  def then_i_should_be_on_the_success_page
    expect(page).to have_path("/appropriate-body/teachers/#{teacher.id}/record-failed-outcome")
    expect(page.locator(".govuk-panel")).to be_visible
  end

  def and_the_pending_induction_submission_record_should_have_the_right_data_in_it
    pending_induction_submission = PendingInductionSubmission.find_by(trn: teacher.trn, appropriate_body:)

    expect(pending_induction_submission.number_of_terms).to eq(number_of_completed_terms)
    expect(pending_induction_submission.finished_on).to eql(today)
    expect(pending_induction_submission.outcome).to eql("fail")
  end

  def and_the_induction_period_should_have_been_closed_with_the_right_data
    induction_period.reload

    expect(induction_period.outcome).to eql("fail")
    expect(induction_period.number_of_terms).to eq(number_of_completed_terms)
    expect(induction_period.finished_on).to eql(today)
  end
end
