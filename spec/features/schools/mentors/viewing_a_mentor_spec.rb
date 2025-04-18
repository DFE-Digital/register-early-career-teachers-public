RSpec.describe "Viewing a mentor" do
  scenario 'Happy path' do
    given_that_i_have_an_active_mentor_with_an_ect
    and_i_sign_in_as_a_school
    when_i_visit_the_index_page
    and_i_click_on_a_mentor
    then_i_am_on_the_mentor_details_page

    given_i_click_on_an_assigned_ect
    and_i_am_on_the_ect_details_page
    when_i_click_the_back_link
    then_i_am_back_on_the_mentor_details_page

    given_i_click_the_back_link
    then_i_am_on_the_mentors_index_page
  end

private

  def given_that_i_have_an_active_mentor_with_an_ect
    start_date = Date.new(2023, 9, 1)

    @school = create(:school, urn: '1234567')
    @mentor_teacher = create(:teacher, trs_first_name: 'Naruto', trs_last_name: 'Uzumaki')
    @mentor = create(:mentor_at_school_period, teacher: @mentor_teacher, school: @school, started_on: start_date, finished_on: nil, id: 1)

    @ect_teacher = create(:teacher, trs_first_name: 'Boruto', trs_last_name: 'Uzumaki')
    @ect = create(
      :ect_at_school_period,
      :provider_led,
      teacher: @ect_teacher,
      school: @school,
      started_on: start_date,
      finished_on: nil
    )

    create(:mentorship_period, mentor: @mentor, mentee: @ect, started_on: start_date, finished_on: nil)
  end

  def given_i_click_on_an_assigned_ect
    page.get_by_role('link', name: 'Boruto Uzumaki').click
  end

  def and_i_am_on_the_ect_details_page
    expect(page.url).to end_with(schools_ect_path(@ect, back_to_mentor: true, mentor_id: @mentor.id))
  end

  def then_i_am_back_on_the_mentor_details_page
    expect(page.url).to end_with(schools_mentor_path(@mentor))
  end

  def and_i_sign_in_as_a_school
    sign_in_as_school_user(school: @school)
  end

  def when_i_visit_the_index_page
    page.goto(schools_mentors_home_path)
  end

  def and_i_click_on_a_mentor
    page.get_by_role('link', name: 'Naruto Uzumaki').click
  end

  def then_i_am_on_the_mentor_details_page
    expect(page.url).to end_with("/schools/mentors/#{@mentor.id}")
  end

  def then_i_am_on_the_mentors_index_page
    expect(page.url).to end_with('/schools/home/mentors')
  end
end
