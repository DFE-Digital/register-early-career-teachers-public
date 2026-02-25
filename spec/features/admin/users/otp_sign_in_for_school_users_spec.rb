RSpec.describe "OTP sign in for school users", :enable_schools_interface do
  scenario "create a user with a school URN and sign in via OTP" do
    given_otp_school_sign_in_is_enabled
    and_a_matching_school_exists
    and_i_am_logged_in_as_a_user_manager
    when_i_create_a_user_with_an_otp_school_urn
    then_i_should_see_the_school_urn_on_the_user_show_page
    when_i_sign_out_and_sign_in_via_otp_as_the_new_user
    then_i_should_be_on_the_school_ects_home_page
  end

private

  def given_otp_school_sign_in_is_enabled
    allow(Rails.application.config).to receive(:enable_otp_school_sign_in).and_return(true)
  end

  def and_a_matching_school_exists
    @otp_school_urn = 123_456
    FactoryBot.create(:gias_school, :open, :state_school_type, :with_school, urn: @otp_school_urn)
  end

  def and_i_am_logged_in_as_a_user_manager
    user_manager = FactoryBot.create(:user, :user_manager)
    sign_in_as_dfe_user(role: :user_manager, user: user_manager)
  end

  def when_i_create_a_user_with_an_otp_school_urn
    @new_user_name = "OTP School User"
    @new_user_email = "otp.school.user@example.com"

    page.goto(admin_users_path)
    page.get_by_role("link", name: "Add new user").click
    page.get_by_label("Name").fill(@new_user_name)
    page.get_by_label("Email address").fill(@new_user_email)
    page.get_by_label("School URN for OTP sign-in").fill(@otp_school_urn.to_s)
    page.get_by_label("Admin").check
    page.get_by_role("button", name: "Add user").click
  end

  def then_i_should_see_the_school_urn_on_the_user_show_page
    page.get_by_role("link", name: @new_user_name).click

    expect(page.get_by_role("heading", name: @new_user_name)).to be_visible
    expect(page.get_by_text("School URN for OTP sign-in")).to be_visible
    expect(page.get_by_text(@otp_school_urn.to_s)).to be_visible
  end

  def when_i_sign_out_and_sign_in_via_otp_as_the_new_user
    sign_out

    otp_user = User.find_by!(email: @new_user_email)
    sign_in_with_otp(user: otp_user)
  end

  def then_i_should_be_on_the_school_ects_home_page
    expect(page).to have_path(schools_ects_home_path)
  end
end
