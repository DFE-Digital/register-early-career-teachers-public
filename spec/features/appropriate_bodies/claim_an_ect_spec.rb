RSpec.describe 'Claiming an ECT' do
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:teacher) { FactoryBot.create(:teacher, trn: '1234567') }
  let(:other_body) { FactoryBot.create(:appropriate_body) }

  before { sign_in_as_appropriate_body_user(appropriate_body:) }

  describe "when the ECT has not passed the induction" do
    let!(:induction_period) do
      FactoryBot.create(:induction_period, teacher:, started_on: 14.months.ago, finished_on: 13.months.ago, appropriate_body: other_body)
    end

    include_context 'fake trs api client that finds teacher with specific induction status', 'InProgress'

    scenario 'Happy path when induction is not completed' do
      given_i_am_on_the_claim_an_ect_find_page
      when_i_enter_a_trn_and_date_of_birth_that_exist_in_trs
      and_i_submit_the_form

      now_i_should_be_on_the_claim_an_ect_check_page
      when_i_begin_the_claim_process

      now_i_should_be_on_the_claim_an_ect_register_page
      when_i_enter_the_start_date
      and_choose_an_induction_programme
      and_i_submit_the_form

      now_i_should_be_on_the_confirmation_page
      and_the_data_i_submitted_should_be_saved_on_the_pending_record
    end
  end

  describe "when the ECT is already claimed by another appropriate body" do
    include_context 'fake trs api client that finds teacher with specific induction status', 'InProgress'

    before do
      FactoryBot.create(:induction_period, :active, teacher:, appropriate_body: other_body)
    end

    scenario 'Button is hidden when induction is ongoing' do
      given_i_am_on_the_claim_an_ect_find_page
      when_i_enter_a_trn_and_date_of_birth_that_exist_in_trs
      and_i_submit_the_form

      now_i_should_be_on_the_claim_an_ect_check_page
      then_i_should_not_see_the_claim_button

      then_i_should_be_told_the_ect_cannot_register
      expect(page.get_by_text('Our records show that Kirk Van Houten is completing their induction with another appropriate body.')).to be_visible
    end
  end

  describe "when the ECT has passed the induction" do
    include_context 'fake trs api client that finds teacher with specific induction status', 'Passed'

    scenario 'Button is hidden when induction is completed' do
      given_i_am_on_the_claim_an_ect_find_page
      when_i_enter_a_trn_and_date_of_birth_that_exist_in_trs
      and_i_submit_the_form

      now_i_should_be_on_the_claim_an_ect_check_page
      then_i_should_not_see_the_claim_button
    end
  end

  describe "when the ECT is exempt from induction" do
    include_context 'fake trs api client that finds teacher with specific induction status', 'Exempt'

    scenario 'Button is hidden and exempt message is shown' do
      given_i_am_on_the_claim_an_ect_find_page
      when_i_enter_a_trn_and_date_of_birth_that_exist_in_trs
      and_i_submit_the_form

      now_i_should_be_on_the_claim_an_ect_check_page
      then_i_should_not_see_the_claim_button

      then_i_should_be_told_the_ect_cannot_register
      expect(page.get_by_text('Our records show that Kirk Van Houten is exempt from completing their induction')).to be_visible
    end
  end

private

  def then_i_should_not_see_the_claim_button
    expect(page.get_by_role('button', name: "Claim induction")).not_to be_visible
  end

  def given_i_am_on_the_claim_an_ect_find_page
    path = '/appropriate-body/claim-an-ect/find-ect/new'
    page.goto(path)
    expect(page.url).to end_with(path)
  end

  def when_i_enter_a_trn_and_date_of_birth_that_exist_in_trs
    page.get_by_label('Teacher reference number').fill('1234567')
    page.get_by_label('Day').fill('1')
    page.get_by_label('Month').fill('2')
    page.get_by_label('Year').fill('2003')
  end

  def when_i_begin_the_claim_process
    page.get_by_role('button', name: "Claim induction").click
  end

  def when_i_submit_the_form
    page.get_by_role('button', name: "Continue").click
  end
  alias_method :and_i_submit_the_form, :when_i_submit_the_form

  def now_i_should_be_on_the_claim_an_ect_check_page
    @pending_induction_submission = PendingInductionSubmission.last
    path = "/appropriate-body/claim-an-ect/check-ect/#{@pending_induction_submission.id}/edit"
    expect(page.url).to end_with(path)
  end

  def now_i_should_be_on_the_claim_an_ect_register_page
    path = "/appropriate-body/claim-an-ect/register-ect/#{@pending_induction_submission.id}/edit"
    expect(page.url).to end_with(path)
  end

  # FIXME: flaky spec, result changes depending on day it is run
  # On 3rd May (2005-05-03) the "finished_on: 13.months.ago" causes the unexpected error
  # Enter a start date after the last induction period finished (3 April 2024)
  #
  def when_i_enter_the_start_date
    @new_start_date = induction_period.finished_on + 1.week

    page.get_by_label('Day').fill(@new_start_date.day.to_s)
    page.get_by_label('Month').fill(@new_start_date.month.to_s)
    page.get_by_label('Year').fill(@new_start_date.year.to_s)
  end

  def and_choose_an_induction_programme
    page.get_by_label("Full induction programme").check
  end

  def now_i_should_be_on_the_confirmation_page
    path = "/appropriate-body/claim-an-ect/register-ect/#{@pending_induction_submission.id}"
    expect(page.url).to end_with(path)
  end

  def and_the_data_i_submitted_should_be_saved_on_the_pending_record
    @pending_induction_submission.reload.tap do |sub|
      expect(sub.date_of_birth).to eql(Date.new(2003, 2, 1))
      expect(sub.trs_first_name).to eql('Kirk')
      expect(sub.trs_last_name).to eql('Van Houten')
      expect(sub.started_on).to eql(@new_start_date)
    end
  end

  def then_i_should_be_told_the_ect_cannot_register
    expect(page.get_by_text('You cannot register Kirk Van Houten')).to be_visible
  end
end
