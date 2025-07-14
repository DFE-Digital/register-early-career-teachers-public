RSpec.describe 'Registering an ECT', :js do
  include_context 'test trs api client'

  let(:trn) { '3002586' }

  scenario 'Teacher with email in use' do
    given_there_is_a_school_in_the_service
    and_an_ongoing_ect_is_assigned_to_the_school
    and_i_sign_in_as_that_school_user
    and_i_am_on_the_schools_landing_page

    when_i_start_adding_an_ect
    and_i_click_the_continue_link
    and_i_submit_the_find_ect_form(trn:, dob_day: '3', dob_month: '2', dob_year: '1977')
    and_i_select_the_ect_details_are_correct
    and_i_click_confirm_and_continue
    and_i_click_continue
    and_i_enter_an_email_address_already_in_use_by_an_ongoing_teacher
    and_i_click_continue
    then_i_should_be_taken_to_the_cant_use_email_page

    when_i_click_try_another_email
    then_i_should_be_taken_to_the_email_address_page

    when_i_enter_an_email_address_of_a_teacher_from_their_finished_school_periods
    and_i_click_continue
    then_i_should_be_taken_to_the_ect_start_date_page
  end

  def and_i_click_the_continue_link
    page.get_by_role('link', name: 'Continue').click
  end

  def given_there_is_a_school_in_the_service
    @school = FactoryBot.create(:school, urn: "1234567")
  end

  def and_i_sign_in_as_that_school_user
    sign_in_as_school_user(school: @school)
  end

  def and_an_ongoing_ect_is_assigned_to_the_school
    @ect = FactoryBot.create(:ect_at_school_period, :active, school: @school)
    @ect_name = Teachers::Name.new(@ect.teacher).full_name
  end

  def and_i_am_on_the_schools_landing_page
    path = '/schools/home/ects'
    page.goto path
    expect(page.url).to end_with(path)
  end

  def when_i_start_adding_an_ect
    page.get_by_role('link', name: 'Register an ECT starting at your school').click
  end

  def and_i_click_continue
    page.get_by_role('button', name: "Continue").click
  end

  def and_i_submit_the_find_ect_form(trn:, dob_day:, dob_month:, dob_year:)
    page.get_by_label('trn').fill(trn)
    page.get_by_label('day').fill(dob_day)
    page.get_by_label('month').fill(dob_month)
    page.get_by_label('year').fill(dob_year)
    page.get_by_role('button', name: 'Continue').click
  end

  def and_i_select_the_ect_details_are_correct
    page.get_by_label("Yes").check
  end

  def and_i_click_confirm_and_continue
    page.get_by_role('button', name: 'Confirm and continue').click
  end

  def then_i_should_be_taken_to_the_email_address_page
    expect(page.url).to end_with('/schools/register-ect/email-address')
  end

  def and_i_enter_an_email_address_already_in_use_by_an_ongoing_teacher
    page.get_by_label('email').fill(@ect.email)
  end

  def when_i_enter_an_email_address_of_a_teacher_from_their_finished_school_periods
    finished_ect = FactoryBot.create(:ect_at_school_period)
    page.get_by_label('email').fill(finished_ect.email)
  end

  def then_i_should_be_taken_to_the_cant_use_email_page
    expect(page.url).to end_with('/schools/register-ect/cant-use-email')
  end

  def when_i_click_try_another_email
    page.get_by_role('link', name: 'Try another email').click
  end

  def then_i_should_be_taken_to_the_ect_start_date_page
    expect(page.url).to end_with('/schools/register-ect/start-date')
  end
end
