RSpec.describe 'Releasing an ECT' do
  let(:page) { RSpec.configuration.playwright_page }
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:trn) { teacher.trn }
  let(:today) { Time.zone.today }
  let(:number_of_completed_terms) { 4 }

  before do
    sign_in_as_appropriate_body_user
    allow_any_instance_of(AppropriateBodies::ReleaseECT).to receive(:release!).and_call_original

    @fake_release_ect = instance_double(AppropriateBodies::ReleaseECT, release!: true)
    allow(AppropriateBodies::ReleaseECT).to receive(:new).and_return(@fake_release_ect)
  end

  let!(:induction_period) { FactoryBot.create(:induction_period, :active, teacher:, appropriate_body: @appropriate_body) }

  scenario 'Happy path' do
    given_i_am_on_the_ect_page(trn)
    when_i_click_link('Release ECT')
    then_i_should_be_on_the_release_ect_page(trn)

    when_i_enter_the_finish_date
    and_i_enter_a_terms_value_of(number_of_completed_terms)
    and_i_click_continue

    then_i_should_be_on_the_success_page
    and_the_pending_induction_submission_record_should_have_the_right_data_in_it
    and_the_release_ect_service_should_have_been_called
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

  def then_i_should_be_on_the_release_ect_page(trn)
    expect(page.url).to end_with("/appropriate-body/teachers/#{trn}/release/new")
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
    expect(page.url).to end_with("/appropriate-body/teachers/#{trn}/release")
    expect(page.locator('.govuk-panel')).to be_present
  end

  def and_the_pending_induction_submission_record_should_have_the_right_data_in_it
    pending_induction_submission = PendingInductionSubmission.find_by(trn:, appropriate_body: @appropriate_body)

    expect(pending_induction_submission.number_of_terms).to eql(number_of_completed_terms)
    expect(pending_induction_submission.finished_on).to eql(today)
  end

  def and_the_release_ect_service_should_have_been_called
    expect(@fake_release_ect).to have_received(:release!).once
  end
end
