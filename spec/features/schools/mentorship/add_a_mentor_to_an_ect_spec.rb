RSpec.describe 'Add a mentor to an ECT' do
  scenario 'happy path' do
    given_there_is_a_school_in_the_service
    and_there_is_an_ect_with_no_mentor_registered_at_the_school
    and_there_is_a_mentor_registered_at_the_school_eligible_to_mentor_the_ect
    and_i_sign_in_as_that_school_user
    and_i_am_on_the_schools_landing_page
    when_i_click_to_assign_a_mentor_to_the_ect
    then_i_am_in_the_who_will_mentor_page

    when_i_select_the_mentor
    then_i_should_be_taken_to_the_mentorship_confirmation_page

    when_i_click_on_back_to_your_ects
    then_i_should_be_taken_to_the_ects_page
    and_the_ect_is_shown_linked_to_the_mentor_just_registered
  end

  def given_there_is_a_school_in_the_service
    @school = create(:school, urn: "1234567")
  end

  def and_i_sign_in_as_that_school_user
    sign_in_as_school_user(school: @school)
  end

  def and_there_is_an_ect_with_no_mentor_registered_at_the_school
    @ect = create(:ect_at_school_period, :active, school: @school)
    @ect_name = Teachers::Name.new(@ect.teacher).full_name
  end

  def and_there_is_a_mentor_registered_at_the_school_eligible_to_mentor_the_ect
    @mentor = create(:mentor_at_school_period, :active, school: @school, started_on: @ect.started_on)
    @mentor_name = Teachers::Name.new(@mentor.teacher).full_name
  end

  def and_i_am_on_the_schools_landing_page
    path = '/schools/home/ects'
    page.goto path
    expect(page.url).to end_with(path)
  end

  def when_i_click_to_assign_a_mentor_to_the_ect
    page.get_by_role(:link, name: 'assign a mentor or register a new one').click
  end

  def then_i_am_in_the_who_will_mentor_page
    expect(page.get_by_text("Who will mentor #{@ect_name}?")).to be_visible
    expect(page.url).to end_with("/school/ects/#{@ect.id}/mentorship/new")
  end

  def when_i_select_the_mentor
    page.get_by_role(:radio, name: @mentor_name).check
    page.get_by_role(:button, name: 'Continue').click
  end

  def then_i_should_be_taken_to_the_mentorship_confirmation_page
    expect(page.url).to end_with("/school/ects/#{@ect.id}/mentorship/confirmation")
    expect(page.get_by_text("You’ve assigned #{@mentor_name} as a mentor for #{@ect_name}")).to be_visible
  end

  def when_i_click_on_back_to_your_ects
    page.get_by_role(:link, name: 'Back to your ECTs').click
  end

  def then_i_should_be_taken_to_the_ects_page
    expect(page.url).to end_with('/schools/home/ects')
  end

  def and_the_ect_is_shown_linked_to_the_mentor_just_registered
    expect(page.get_by_role(:link, name: @ect_name)).to be_visible
    expect(page.locator('dt', hasText: 'Mentor')).to be_visible
    expect(page.locator('dd', hasText: @mentor_name)).to be_visible
  end
end
