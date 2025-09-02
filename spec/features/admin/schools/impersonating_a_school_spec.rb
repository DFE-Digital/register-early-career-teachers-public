RSpec.describe 'Impersonating a school user' do
  let(:admin_user) { FactoryBot.create(:user, :admin) }
  let(:school) { FactoryBot.create(:school) }

  before { sign_in_as_dfe_user(role: :admin, user: admin_user) }

  scenario 'impersonating' do
    given_i_am_on_the_admin_show_page_for_a_school
    when_i_click_sign_in_as_school
    then_i_should_be_on_the_schools_home_page
    and_i_should_be_impersonating_the_school

    when_i_click_sign_out
    then_i_should_be_on_the_admin_school_show_page
  end

private

  def given_i_am_on_the_admin_show_page_for_a_school
    path = "/admin/schools/#{school.urn}/overview"
    page.goto(path)

    expect(page.url).to end_with(path)
  end

  def when_i_click_sign_in_as_school
    page.get_by_role('button', name: "Sign in as #{school.name}").click
  end

  def then_i_should_be_on_the_schools_home_page
    expect(page.url).to end_with('/schools/home/ects')
  end

  def and_i_should_be_impersonating_the_school
    body = page.locator('body')

    expect(body).to have_text("You are signed in as #{school.name}")
  end

  def when_i_click_sign_out
    page.get_by_role('button', name: "Sign out from #{school.name}").click
  end

  def then_i_should_be_on_the_admin_school_show_page
    path = "/admin/schools/#{school.urn}/overview"

    expect(page.url).to end_with(path)
  end
end
