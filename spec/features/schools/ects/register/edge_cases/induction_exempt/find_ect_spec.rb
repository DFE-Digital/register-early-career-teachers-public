RSpec.describe 'Registering an ECT' do
  include_context 'fake trs api client that finds teacher that is exempt from induction'

  scenario 'User enters date of birth (find ECT step) but teacher has completed their induction' do
    given_i_am_logged_in_as_a_school_user

    when_i_am_on_the_find_ect_step_page
    and_i_submit_a_date_of_birth_and_trn_of_a_teacher_that_has_completed_their_induction
    then_i_am_taken_to_the_teacher_has_completed_their_induction_error_page

    when_i_click_register_another_ect
    then_i_am_taken_to_the_find_ect_step_page
  end

  def given_i_am_logged_in_as_a_school_user
    school = create(:school)
    sign_in_as_school_user(school:)
  end

  def when_i_am_on_the_find_ect_step_page
    page.goto('/schools/register-ect/find-ect')
  end

  def and_i_submit_a_date_of_birth_and_trn_of_a_teacher_that_has_completed_their_induction
    page.get_by_label('trn').fill('9876543')
    page.get_by_label('day').fill('3')
    page.get_by_label('month').fill('2')
    page.get_by_label('year').fill('1977')
    page.get_by_role('button', name: 'Continue').click
  end

  def then_i_am_taken_to_the_teacher_has_completed_their_induction_error_page
    expect(page.url).to end_with('/schools/register-ect/induction-exempt')
  end

  def when_i_click_register_another_ect
    page.get_by_role('link', name: 'Register another ECT').click
  end

  def then_i_am_taken_to_the_find_ect_step_page
    expect(page.url).to end_with('/schools/register-ect/find-ect')
  end
end
