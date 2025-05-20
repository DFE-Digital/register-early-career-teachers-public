RSpec.describe 'Registering an ECT' do
  include_context 'fake trs api returns a teacher and then a teacher that has failed their induction'

  scenario 'User enters national insurance number but teacher has failed their induction' do
    given_i_am_logged_in_as_a_school_user
    when_i_am_on_the_find_ect_step_page
    and_i_submit_a_date_of_birth_that_does_not_match
    and_i_enter_a_matching_national_insurance_number_but_the_teacher_has_failed_their_induction
    then_i_am_taken_to_the_teacher_has_failed_their_induction_error_page

    when_i_click_register_another_ect
    then_i_am_taken_to_the_find_ect_step_page
  end

  def given_i_am_logged_in_as_a_school_user
    school = FactoryBot.create(:school)
    sign_in_as_school_user(school:)
  end

  def when_i_am_on_the_find_ect_step_page
    page.goto('/schools/register-ect/find-ect')
  end

  def and_i_submit_a_date_of_birth_that_does_not_match
    page.get_by_label('trn').fill('9876543')
    page.get_by_label('day').fill('1')
    page.get_by_label('month').fill('2')
    page.get_by_label('year').fill('1980')
    page.get_by_role('button', name: 'Continue').click
  end

  def then_i_am_taken_to_the_teacher_has_failed_their_induction_error_page
    expect(page.url).to end_with('/schools/register-ect/induction-failed')
  end

  def and_i_enter_a_matching_national_insurance_number_but_the_teacher_has_failed_their_induction
    page.get_by_label("National Insurance Number").fill("OA647867D")
    page.get_by_role('button', name: 'Continue').click
  end

  def when_i_click_register_another_ect
    page.get_by_role('link', name: 'Register another ECT').click
  end

  def then_i_am_taken_to_the_find_ect_step_page
    expect(page.url).to end_with('/schools/register-ect/find-ect')
  end
end
