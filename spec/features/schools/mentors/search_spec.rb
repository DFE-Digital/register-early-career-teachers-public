RSpec.describe "Searching for a mentor" do
  include_context "test TRS API returns a teacher"

  before do
    given_there_is_a_school_with_teachers
    and_i_am_logged_in_as_a_school_user
    and_i_am_on_the_mentor_list_page
  end

  scenario "shows matching teachers when searching by name" do
    when_i_search_for_a_teacher

    then_i_should_see_the_matching_teacher
    and_i_should_not_see_the_non_matching_teacher
  end

  scenario "shows matching teachers when searching by TRN" do
    when_i_search_for_a_teacher_by_trn

    then_i_should_see_the_matching_teacher
    and_i_should_not_see_the_non_matching_teacher
  end

  scenario "when no results are found, keeps the search box visible and shows a no-results message" do
    when_i_search_for_a_teacher_that_does_not_exist

    then_i_should_see_the_search_box
    and_i_should_see_the_no_results_message
    and_i_should_not_see_the_no_mentors_registered_message
  end

  scenario "shows a no mentors message and no search box when the school has no mentors" do
    given_the_school_has_no_mentors

    then_i_should_see_the_no_mentors_message
    and_i_should_not_see_the_search_box
  end

  def when_i_search_for_a_teacher_by_trn
    page.get_by_label("Search by name or teacher reference number (TRN)").fill(@matching_teacher.trn)
    page.get_by_role("button", name: "Search").click
  end

  def given_there_is_a_school_with_teachers
    @school = FactoryBot.create(:school)

    @matching_teacher = FactoryBot.create(:teacher, trs_first_name: "Jimmy", trs_last_name: "Searchable")
    FactoryBot.create(:mentor_at_school_period, :ongoing, teacher: @matching_teacher, school: @school)

    @non_matching_teacher = FactoryBot.create(:teacher, trs_first_name: "Bob", trs_last_name: "Invisible")
    FactoryBot.create(:mentor_at_school_period, :ongoing, teacher: @non_matching_teacher, school: @school)
  end

  def and_i_am_logged_in_as_a_school_user
    sign_in_as_school_user(school: @school)
  end

  def and_i_am_on_the_mentor_list_page
    page.goto("/school/home/mentors")
  end

  def when_i_search_for_a_teacher
    page.get_by_label("Search by name or teacher reference number (TRN)").fill(@matching_teacher.trs_first_name)
    page.get_by_role("button", name: "Search").click
  end

  def then_i_should_see_the_matching_teacher
    expect(page.get_by_role("link", name: "Jimmy Searchable")).to be_visible
  end

  def and_i_should_not_see_the_non_matching_teacher
    expect(page.get_by_role("link", name: "Bob Invisible")).not_to be_visible
  end

  def when_i_search_for_a_teacher_that_does_not_exist
    page.get_by_label("Search by name or teacher reference number (TRN)").fill("Nonexistent Person")
    page.get_by_role("button", name: "Search").click
  end

  def then_i_should_see_the_search_box
    expect(page.get_by_label("Search by name or teacher reference number (TRN)")).to be_visible
  end

  def and_i_should_see_the_no_results_message
    expect(page.get_by_text("There are no mentors that match your search")).to be_visible
  end

  def and_i_should_not_see_the_no_mentors_registered_message
    expect(page.get_by_text("no registered mentors", exact: false)).not_to be_visible
  end

  def given_the_school_has_no_mentors
    MentorAtSchoolPeriod.where(school: @school).find_each(&:destroy)
    page.goto("/school/home/mentors")
  end

  def then_i_should_see_the_no_mentors_message
    expect(page.get_by_text("Your school currently has no registered mentors")).to be_visible
  end

  def and_i_should_not_see_the_search_box
    expect(page.get_by_label("Search by name or teacher reference number (TRN)")).not_to be_visible
  end
end
