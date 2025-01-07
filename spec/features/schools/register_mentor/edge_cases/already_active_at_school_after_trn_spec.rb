RSpec.describe 'Registering a mentor', :js do
  include_context 'fake trs api client'

  scenario 'mentor already active at the school from trn and dob' do
    given_there_is_a_school_in_the_service
    and_there_is_an_ect_with_no_mentor_registered_at_the_school
    and_there_is_an_active_mentor_registered_at_the_school
    and_i_sign_in_as_that_school_user
    then_i_am_on_the_schools_landing_page

    when_i_click_to_assign_a_mentor_to_the_ect
    then_i_am_in_the_who_will_mentor_page

    when_i_select_register_a_new_mentor
    then_i_am_in_the_requirements_page

    when_i_click_continue
    then_i_should_be_taken_to_the_find_mentor_page

    when_i_submit_the_find_mentor_form_with_the_existing_mentor_data
    then_i_should_be_taken_to_the_already_active_at_school_page

    when_i_click_to_assign_the_existing_mentor_to_the_ect
    then_i_should_be_taken_to_the_confirmation_page

    when_i_click_on_back_to_ects
    then_i_should_be_taken_to_the_ects_page
    and_the_ect_is_shown_linked_to_the_existing_mentor
  end

  def given_there_is_a_school_in_the_service
    @school = FactoryBot.create(:school, urn: "1234567")
  end

  def and_there_is_an_ect_with_no_mentor_registered_at_the_school
    @ect = FactoryBot.create(:ect_at_school_period, :active, school: @school)
    @ect_name = Teachers::Name.new(@ect.teacher).full_name
  end

  def and_there_is_an_active_mentor_registered_at_the_school
    teacher = FactoryBot.create(:teacher, first_name: 'Kirk', last_name: 'Van Houten', corrected_name: nil)
    @mentor = FactoryBot.create(:mentor_at_school_period, :active, school: @school, teacher:)
    @mentor_name = Teachers::Name.new(teacher).full_name
  end

  def and_i_sign_in_as_that_school_user
    sign_in_as_school_user(school: @school)
  end

  def then_i_am_on_the_schools_landing_page
    path = '/schools/home/ects'
    page.goto path
    expect(page.url).to end_with(path)
  end

  def when_i_click_to_assign_a_mentor_to_the_ect
    page.get_by_role('link', name: 'assign a mentor or register a new one').click
  end

  def then_i_am_in_the_who_will_mentor_page
    expect(page.get_by_text("Who will mentor #{@ect_name}?")).to be_visible
    expect(page.url).to end_with("/school/ects/#{@ect.id}/mentorship/new")
  end

  def when_i_select_register_a_new_mentor
    page.get_by_role(:radio, name: "Register a new mentor").check
    page.get_by_role(:button, name: 'Continue').click
  end

  def then_i_am_in_the_requirements_page
    expect(page.get_by_text("What you'll need to add a new mentor for #{@ect_name}")).to be_visible
    expect(page.url).to end_with("/school/register-mentor/what-you-will-need?ect_id=#{@ect.id}")
  end

  def when_i_click_continue
    page.get_by_role('link', name: 'Continue').click
  end

  def then_i_should_be_taken_to_the_find_mentor_page
    path = '/school/register-mentor/find-mentor'
    expect(page.url).to end_with(path)
  end

  def when_i_submit_the_find_mentor_form_with_the_existing_mentor_data
    page.get_by_label('trn').fill(@mentor.teacher.trn)
    page.get_by_label('day').fill('3')
    page.get_by_label('month').fill('2')
    page.get_by_label('year').fill('1977')
    page.get_by_role('button', name: 'Continue').click
  end

  def then_i_should_be_taken_to_the_already_active_at_school_page
    expect(page.url).to end_with('/school/register-mentor/already-active-at-school')
  end

  def when_i_click_to_assign_the_existing_mentor_to_the_ect
    page.get_by_role('button', name: "Assign #{@ect_name} to mentor #{@mentor_name}").click
  end

  def then_i_should_be_taken_to_the_confirmation_page
    expect(page.url).to end_with('/school/register-mentor/confirmation')
  end

  def when_i_click_on_back_to_ects
    page.get_by_role('link', name: 'Back to ECTs').click
  end

  def then_i_should_be_taken_to_the_ects_page
    expect(page.url).to end_with('/schools/home/ects')
  end

  def and_the_ect_is_shown_linked_to_the_existing_mentor
    expect(page.get_by_text("Kirk Van Houten")).to be_visible
    expect(page.get_by_text(@ect_name)).to be_visible
  end
end
