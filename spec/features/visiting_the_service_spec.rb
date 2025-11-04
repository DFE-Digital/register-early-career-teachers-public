RSpec.describe 'Visiting the service' do
  context 'when the schools interface is disabled' do
    before do
      allow(Rails.application.config).to receive(:enable_schools_interface).and_return(false)
    end

    scenario 'the home page is the appropriate body landing page' do
      given_i_browse_to("/")
      then_i_am_redirected_to_the_ab_landing_page
    end
  end

  context 'when the schools interface is enabled' do
    before do
      allow(Rails.application.config).to receive(:enable_schools_interface).and_return(true)
    end

    scenario 'the home page is the school landing page' do
      given_i_browse_to("/")
      then_i_see_the_school_landing_page
    end
  end

  context 'when accessing restricted areas' do
    scenario 'Admin console redirects to authenticate' do
      given_i_browse_to("/admin")
      then_i_see_the_admin_sign_in_page
    end

    scenario 'Blazer redirects to authenticate' do
      given_i_browse_to("/admin/blazer")
      then_i_see_the_admin_sign_in_page
    end

    scenario 'MissionControl redirects to authenticate' do
      given_i_browse_to("/admin/jobs")
      then_i_see_the_admin_sign_in_page
    end
  end

private

  def given_i_browse_to(path)
    page.goto(path)
  end

  def then_i_am_redirected_to_the_ab_landing_page
    expect(page).to have_path('/appropriate-body')
    expect(page.title).to start_with('Record inductions as an appropriate body')
  end

  def then_i_see_the_school_landing_page
    expect(page).to have_path('/')
    expect(page.title).to start_with('Register early career teachers')
  end

  def then_i_see_the_admin_sign_in_page
    expect(page).to have_path('/sign-in')
    expect(page.title).to start_with('Select a sign in method')
  end
end
