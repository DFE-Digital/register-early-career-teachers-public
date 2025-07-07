RSpec.describe 'Searching for an ECT', type: :feature do
  include_context 'fake trs api client'

  before do
    given_there_is_a_school_with_teachers
    and_i_am_logged_in_as_a_school_user
    and_i_am_on_the_ects_list_page
  end

  scenario 'shows matching teachers when searching by name' do
    when_i_search_for_a_teacher

    then_i_should_see_the_matching_teacher
    and_i_should_not_see_the_non_matching_teacher
  end

  scenario 'shows matching teachers when searching by TRN' do
    when_i_search_for_a_teacher_by_trn

    then_i_should_see_the_matching_teacher
    and_i_should_not_see_the_non_matching_teacher
  end

  def when_i_search_for_a_teacher_by_trn
    page.get_by_label("Search by name or teacher reference number (TRN)").fill(@matching_teacher.trn)
    page.get_by_role("button", name: "Search").click
  end

  def given_there_is_a_school_with_teachers
    @school = create(:school)

    @matching_teacher = create(:teacher, trs_first_name: 'Jimmy', trs_last_name: 'Searchable')
    create(:ect_at_school_period, :active, teacher: @matching_teacher, school: @school)

    @non_matching_teacher = create(:teacher, trs_first_name: 'Bob', trs_last_name: 'Invisible')
    create(:ect_at_school_period, :active, teacher: @non_matching_teacher, school: @school)
  end

  def and_i_am_logged_in_as_a_school_user
    sign_in_as_school_user(school: @school)
  end

  def and_i_am_on_the_ects_list_page
    page.goto('/schools/home/ects')
  end

  def when_i_search_for_a_teacher
    page.get_by_label('Search by name or teacher reference number (TRN)').fill(@matching_teacher.trs_first_name)
    page.get_by_role('button', name: 'Search').click
  end

  def then_i_should_see_the_matching_teacher
    expect(page.get_by_text('Jimmy Searchable')).to be_visible
  end

  def and_i_should_not_see_the_non_matching_teacher
    expect(page.get_by_text('Bob Invisible')).not_to be_visible
  end
end
