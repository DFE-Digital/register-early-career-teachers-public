RSpec.describe 'Admin importing an ECT' do
  let(:admin_user) { FactoryBot.create(:user, :admin) }

  before { sign_in_as_dfe_user(role: :admin, user: admin_user) }

  describe "Happy path - importing a valid teacher" do
    include_context 'test trs api client'

    scenario 'Successfully import an ECT from TRS' do
      given_i_am_on_the_admin_teachers_index_page
      when_i_click_the_import_ect_button

      then_i_should_be_on_the_find_ect_page
      when_i_enter_a_trn_and_date_of_birth_that_exist_in_trs
      and_i_click_continue

      then_i_should_be_on_the_check_ect_page
      and_i_should_see_the_ect_details
      when_i_click_continue

      then_i_should_be_on_the_register_ect_page
      and_i_should_see_the_success_message
      and_the_teacher_should_be_created_in_the_database
      and_no_induction_period_should_be_created
    end
  end

  describe "Error cases" do
    context "when teacher not found in TRS" do
      include_context 'test trs api client that finds nothing'

      scenario 'Shows teacher not found error' do
        given_i_am_on_the_find_ect_page
        when_i_enter_a_trn_and_date_of_birth_that_do_not_exist_in_trs
        and_i_click_continue

        then_i_should_see_the_teacher_not_found_error
      end
    end

    context "when teacher already exists in RIAB" do
      include_context 'test trs api client'

      let!(:existing_teacher) { FactoryBot.create(:teacher, trn: '1234567') }

      scenario 'Redirects to existing teacher page' do
        given_i_am_on_the_find_ect_page
        when_i_enter_a_trn_for_existing_teacher
        and_i_click_continue

        then_i_should_be_redirected_to_the_existing_teacher_page
        and_i_should_see_the_teacher_already_exists_message
      end
    end

    context "when teacher does not have QTS" do
      include_context 'test trs api client that finds teacher without QTS'

      scenario 'Shows QTS not awarded error page' do
        given_i_am_on_the_find_ect_page
        when_i_enter_a_trn_and_date_of_birth_that_exist_in_trs
        and_i_click_continue

        then_i_should_be_on_the_no_qts_error_page
        and_i_should_see_the_qts_error_message
      end
    end

    context "when teacher is prohibited from teaching" do
      include_context 'test trs api client that finds teacher prohibited from teaching'

      scenario 'Shows prohibited from teaching error page' do
        given_i_am_on_the_find_ect_page
        when_i_enter_a_trn_and_date_of_birth_that_exist_in_trs
        and_i_click_continue

        then_i_should_be_on_the_prohibited_error_page
        and_i_should_see_the_prohibited_error_message
      end
    end
  end

  describe "Navigation and UI" do
    scenario 'Import TRS record button is available on admin console homepage' do
      given_i_am_on_the_admin_teachers_index_page
      then_i_should_see_the_import_ect_button
    end
  end

private

  def given_i_am_on_the_admin_teachers_index_page
    path = '/admin/teachers'
    page.goto(path)
    expect(page.url).to end_with(path)
  end

  def given_i_am_on_the_find_ect_page
    path = '/admin/import-ect/find-ect/new'
    page.goto(path)
    expect(page.url).to end_with(path)
  end

  def then_i_should_see_the_import_ect_button
    expect(page.get_by_role('link', name: 'Import TRS record')).to be_visible
  end

  def when_i_click_the_import_ect_button
    page.get_by_role('link', name: 'Import TRS record').click
  end

  def then_i_should_be_on_the_find_ect_page
    expect(page.url).to end_with('/admin/import-ect/find-ect/new')
    expect(page.get_by_text('Find an early career teacher')).to be_visible
  end

  def when_i_enter_a_trn_and_date_of_birth_that_exist_in_trs
    page.get_by_label('Teacher reference number').fill('1234567')
    page.get_by_label('Day').fill('1')
    page.get_by_label('Month').fill('2')
    page.get_by_label('Year').fill('2003')
  end

  def when_i_enter_a_trn_and_date_of_birth_that_do_not_exist_in_trs
    page.get_by_label('Teacher reference number').fill('9999999')
    page.get_by_label('Day').fill('1')
    page.get_by_label('Month').fill('2')
    page.get_by_label('Year').fill('2003')
  end

  def when_i_enter_a_trn_for_existing_teacher
    page.get_by_label('Teacher reference number').fill('1234567')
    page.get_by_label('Day').fill('1')
    page.get_by_label('Month').fill('2')
    page.get_by_label('Year').fill('2003')
  end

  def and_i_click_continue
    page.get_by_role('button', name: 'Continue').click
  end

  def then_i_should_be_on_the_check_ect_page
    @pending_induction_submission = PendingInductionSubmission.last
    path = "/admin/import-ect/check-ect/#{@pending_induction_submission.id}/edit"
    expect(page.url).to end_with(path)
  end

  def and_i_should_see_the_ect_details
    expect(page.get_by_text('Kirk Van Houten')).to be_visible
    expect(page.get_by_text('1234567')).to be_visible
    expect(page.get_by_text('1 February 2003')).to be_visible
  end

  def when_i_click_continue
    page.get_by_role('button', name: 'Continue').click
  end

  def then_i_should_be_on_the_register_ect_page
    path = "/admin/import-ect/register-ect/#{@pending_induction_submission.id}"
    expect(page.url).to end_with(path)
  end

  def and_i_should_see_the_success_message
    expect(page.get_by_text("You've successfully imported Kirk Van Houten's induction")).to be_visible
  end

  def and_the_teacher_should_be_created_in_the_database
    teacher = Teacher.find_by(trn: '1234567')
    expect(teacher).to be_present
    expect(teacher.trs_first_name).to eq('Kirk')
    expect(teacher.trs_last_name).to eq('Van Houten')
  end

  def and_no_induction_period_should_be_created
    expect(InductionPeriod.count).to eq(0)
  end

  def then_i_should_see_the_teacher_not_found_error
    expect(page.get_by_text('No teacher with this TRN and date of birth was found')).to be_visible
  end

  def then_i_should_be_redirected_to_the_existing_teacher_page
    teacher = Teacher.find_by(trn: '1234567')
    expect(page.url).to end_with("/admin/teachers/#{teacher.id}")
  end

  def and_i_should_see_the_teacher_already_exists_message
    teacher = Teacher.find_by(trn: '1234567')
    expect(page.get_by_text("Teacher #{teacher.trn} already exists in the system")).to be_visible
  end

  def then_i_should_be_on_the_no_qts_error_page
    @pending_induction_submission = PendingInductionSubmission.last
    path = "/admin/import-ect/errors/no-qts/#{@pending_induction_submission.id}"
    expect(page.url).to end_with(path)
  end

  def and_i_should_see_the_qts_error_message
    expect(page.get_by_text('You cannot register')).to be_visible
    expect(page.get_by_text('does not have their qualified teacher status')).to be_visible
  end

  def then_i_should_be_on_the_prohibited_error_page
    @pending_induction_submission = PendingInductionSubmission.last
    path = "/admin/import-ect/errors/prohibited-from-teaching/#{@pending_induction_submission.id}"
    expect(page.url).to end_with(path)
  end

  def and_i_should_see_the_prohibited_error_message
    expect(page.get_by_text('You cannot register')).to be_visible
    expect(page.get_by_text('is prohibited from teaching')).to be_visible
  end
end
