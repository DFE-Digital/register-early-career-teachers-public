RSpec.describe 'Registering an ECT' do
  include_context 'fake trs api client'

  scenario 'Teacher with trn has already registered as an ECT at a school' do
    given_i_am_logged_in_as_a_school_user
    and_an_ect_has_already_registered_at_my_school
    and_i_am_on_the_find_ect_step_page

    when_i_submit_the_details_of_the_ect_already_registered
    then_i_should_be_taken_to_the_ect_already_registered_error_page

    when_i_click_try_again
    then_i_should_be_taken_to_the_find_ect_step_page
  end

  def school
    @school ||= FactoryBot.create(:school)
  end

  def given_i_am_logged_in_as_a_school_user
    sign_in_as_school_user(school:)
  end

  def and_an_ect_has_already_registered_at_my_school
    teacher = FactoryBot.create(:teacher, trn: '9876543')
    FactoryBot.create(:ect_at_school_period, :active, teacher: teacher, school:)
  end

  def when_i_click_continue
    page.get_by_role('link', name: 'Continue').click
  end

  def and_i_am_on_the_find_ect_step_page
    path = '/schools/register-ect/find-ect'
    page.goto path
    expect(page.url).to end_with(path)
  end

  def when_i_submit_the_details_of_the_ect_already_registered
    page.get_by_label('trn').fill('9876543')
    page.get_by_label('day').fill('3')
    page.get_by_label('month').fill('2')
    page.get_by_label('year').fill('1977')
    page.get_by_role('button', name: 'Continue').click
  end

  def then_i_should_be_taken_to_the_ect_already_registered_error_page
    expect(page.url).to end_with('/schools/register-ect/already_active_at_school')
  end

  def when_i_click_try_again
    page.get_by_role('link', name: 'Register another ECT').click
  end

  def then_i_should_be_taken_to_the_find_ect_step_page
    path = '/schools/register-ect/find-ect'
    expect(page.url).to end_with(path)
  end
end
