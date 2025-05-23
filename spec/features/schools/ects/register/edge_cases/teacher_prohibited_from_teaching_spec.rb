RSpec.describe 'Registering an ECT' do
  include_context 'fake trs api client that finds teacher prohibited from teaching'

  scenario 'The ECT is prohibited from teaching' do
    given_i_am_logged_in_as_a_school_user
    when_i_am_on_the_find_ect_step_page
    and_i_submit_details_of_a_prohibited_teacher
    then_i_should_be_taken_to_the_cannot_register_ect_page

    when_i_click_back_to_ects
    then_i_should_be_taken_to_the_school_ects_page
  end

  def given_i_am_logged_in_as_a_school_user
    school = FactoryBot.create(:school)
    sign_in_as_school_user(school:)
  end

  def when_i_am_on_the_find_ect_step_page
    path = '/schools/register-ect/find-ect'
    page.goto path
    expect(page.url).to end_with(path)
  end

  def and_i_submit_details_of_a_prohibited_teacher
    page.get_by_label('trn').fill('9876543')
    page.get_by_label('day').fill('3')
    page.get_by_label('month').fill('2')
    page.get_by_label('year').fill('1977')
    page.get_by_role('button', name: 'Continue').click
  end

  def then_i_should_be_taken_to_the_cannot_register_ect_page
    path = '/schools/register-ect/cannot-register-ect'
    expect(page.url).to end_with(path)
  end

  def when_i_click_back_to_ects
    page.get_by_role('link', name: 'Back to ECTs').click
  end

  def then_i_should_be_taken_to_the_school_ects_page
    path = '/schools/home/ects'
    expect(page.url).to end_with(path)
  end
end
