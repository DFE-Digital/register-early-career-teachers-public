RSpec.describe "Recording a failed outcome for an ECT" do
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:trn) { teacher.trn }
  let(:today) { Time.zone.today }
  let(:number_of_completed_terms) { 4 }

  before { sign_in_as_appropriate_body_user(appropriate_body:) }

  let!(:induction_period) { FactoryBot.create(:induction_period, :active, teacher:, appropriate_body:) }

  scenario 'Happy path' do
    given_i_am_on_the_ect_page(trn)
    when_i_click_link('Fail induction')
    then_i_should_be_on_the_record_outcome_page(trn)

    when_i_enter_the_finish_date
    and_i_enter_a_terms_value_of(number_of_completed_terms)
    and_i_click_submit

    then_i_should_be_on_the_success_page
    and_the_pending_induction_submission_record_should_have_the_right_data_in_it
    and_the_induction_period_should_have_been_closed_with_the_right_data
  end

private

  def given_i_am_on_the_ect_page(trn)
    path = "/appropriate-body/teachers/#{trn}"
    page.goto(path)
    expect(page.url).to end_with(path)
  end

  def when_i_click_link(text)
    page.get_by_role('link', name: text).click
  end

  def then_i_should_be_on_the_record_outcome_page(trn)
    expect(page.url).to end_with("/appropriate-body/teachers/#{trn}/record-failed-outcome/new")
  end

  def when_i_enter_the_finish_date
    page.get_by_label('Day', exact: true).fill(today.day.to_s)
    page.get_by_label('Month', exact: true).fill(today.month.to_s)
    page.get_by_label('Year', exact: true).fill(today.year.to_s)
  end

  def and_i_enter_a_terms_value_of(number)
    teacher_name = Teachers::Name.new(teacher).full_name
    label = "How many terms of induction did #{teacher_name} spend with you?"

    page.get_by_label(label).fill(number.to_s)
  end

  def and_i_click_submit
    teacher_name = Teachers::Name.new(teacher).full_name
    page.get_by_role('button', name: "Record failing outcome for #{teacher_name}").click
  end

  def then_i_should_be_on_the_success_page
    expect(page.url).to end_with("/appropriate-body/teachers/#{trn}/record-failed-outcome")
    expect(page.locator('.govuk-panel')).to be_visible
  end

  def and_the_pending_induction_submission_record_should_have_the_right_data_in_it
    pending_induction_submission = PendingInductionSubmission.find_by(trn:, appropriate_body:)

    expect(pending_induction_submission.number_of_terms).to eql(number_of_completed_terms)
    expect(pending_induction_submission.finished_on).to eql(today)
    expect(pending_induction_submission.outcome).to eql('fail')
  end

  def and_the_induction_period_should_have_been_closed_with_the_right_data
    induction_period.reload

    expect(induction_period.outcome).to eql('fail')
    expect(induction_period.number_of_terms).to eql(number_of_completed_terms)
    expect(induction_period.finished_on).to eql(today)
  end
end
