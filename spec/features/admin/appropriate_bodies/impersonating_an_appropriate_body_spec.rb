RSpec.describe "Impersonating an appropriate body user" do
  scenario "successfully impersonating an appropriate body user" do
    given_i_am_signed_in_as_an_admin_user
    and_i_am_on_the_admin_show_page_for_an_appropriate_body

    when_i_click_sign_in_as_appropriate_body
    then_i_should_be_on_the_appropriate_bodies_home_page
    and_i_should_be_impersonating_the_appropriate_body
    and_i_should_see_the_same_options_an_appropriate_body_sees

    when_i_click_sign_out
    then_i_should_be_on_the_admin_appropriate_body_show_page
  end

  scenario "not being able to access the admin pages while impersonating" do
    given_i_am_signed_in_as_an_admin_user
    and_i_am_on_the_admin_show_page_for_an_appropriate_body

    when_i_click_sign_in_as_appropriate_body
    then_i_should_be_on_the_appropriate_bodies_home_page

    when_i_navigate_back_to_the_admin_interface
    then_i_should_see_an_access_denied_error
  end

private

  def given_i_am_signed_in_as_an_admin_user
    admin_user = FactoryBot.create(:user, :admin)
    sign_in_as_dfe_user(role: :admin, user: admin_user)
  end

  def and_i_am_on_the_admin_show_page_for_an_appropriate_body
    @appropriate_body = FactoryBot.create(:appropriate_body_period)
    path = "/admin/organisations/appropriate-bodies/#{@appropriate_body.id}"
    page.goto(path)

    expect(page).to have_path(path)
  end

  def when_i_click_sign_in_as_appropriate_body
    page.get_by_role("button", name: "Sign in as #{@appropriate_body.name}").click
  end

  def then_i_should_be_on_the_appropriate_bodies_home_page
    expect(page).to have_path("/appropriate-body/teachers")
  end

  def and_i_should_be_impersonating_the_appropriate_body
    body = page.locator("body")

    expect(body).to have_text("You are signed in as #{@appropriate_body.name}")
  end

  def and_i_should_see_the_same_options_an_appropriate_body_sees
    expect(page.get_by_role("link", name: "Find and claim a new ECT")).to be_visible
    expect(page.get_by_role("link", name: "Claim multiple ECTs")).to be_visible
  end

  def when_i_click_sign_out
    page.get_by_role("button", name: "Sign out from #{@appropriate_body.name}").click
  end

  def then_i_should_be_on_the_admin_appropriate_body_show_page
    path = "/admin/organisations/appropriate-bodies/#{@appropriate_body.id}"

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
