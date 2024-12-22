RSpec.describe "Admin root" do
  include UserHelper
  scenario "visiting the admin placeholder page" do
    given_i_am_logged_in_as_an_admin
    when_i_visit_the_admin_root_page
    then_i_should_see_the_admin_teacher_search_page
  end

  def given_i_am_logged_in_as_an_admin
    sign_in_as_dfe_user(role: :admin)
  end

  def when_i_visit_the_admin_root_page
    page.goto(admin_path)
  end

  def then_i_should_see_the_admin_teacher_search_page
    expect(page.get_by_text("Search by name or TRN")).to be_visible
  end
end
