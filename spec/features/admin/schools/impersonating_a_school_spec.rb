RSpec.describe "Impersonating a school user", :enable_schools_interface do
  scenario "successfully impersonating a school user" do
    given_i_am_signed_in_as_an_admin_user
    and_i_am_on_the_admin_show_page_for_a_school

    when_i_click_sign_in_as_school
    then_i_should_be_on_the_schools_home_page
    and_i_should_be_impersonating_the_school

    when_i_click_sign_out
    then_i_should_be_on_the_admin_school_show_page
  end

  scenario "not being able to access the admin pages while impersonating" do
    given_i_am_signed_in_as_an_admin_user
    and_i_am_on_the_admin_show_page_for_a_school

    when_i_click_sign_in_as_school
    then_i_should_be_on_the_schools_home_page

    when_i_navigate_back_to_the_admin_interface
    then_i_should_see_an_access_denied_error
  end

  private

  def given_i_am_signed_in_as_an_admin_user
    admin_user = FactoryBot.create(:user, :admin)
    sign_in_as_dfe_user(role: :admin, user: admin_user)
  end

  def and_i_am_on_the_admin_show_page_for_a_school
    @school = FactoryBot.create(:school)
    path = "/admin/schools/#{@school.urn}/overview"
    page.goto(path)

    expect(page).to have_path(path)
  end

  def when_i_click_sign_in_as_school
    page.get_by_role("button", name: "Sign in as #{@school.name}").click
  end

  def then_i_should_be_on_the_schools_home_page
    expect(page).to have_path("/school/home/ects")
  end

  def and_i_should_be_impersonating_the_school
    body = page.locator("body")

    expect(body).to have_text("You are signed in as #{@school.name}")
  end

  def when_i_click_sign_out
    page.get_by_role("button", name: "Sign out from #{@school.name}").click
  end

  def then_i_should_be_on_the_admin_school_show_page
    path = "/admin/schools/#{@school.urn}/overview"

    expect(page).to have_path(path)
  end

  def when_i_navigate_back_to_the_admin_interface
    path = "/admin/teachers"
    page.goto(path)

    expect(page).to have_path(path)
  end

  def then_i_should_see_an_access_denied_error
    expect(page.get_by_role("heading", name: "You are not authorised to access this page")).to be_visible
  end
end
