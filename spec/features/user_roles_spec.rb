RSpec.describe "User roles", :enable_schools_interface do
  let(:school) { FactoryBot.create(:school, :state_funded) }
  let(:appropriate_body) { FactoryBot.create(:appropriate_body, name: school.name) }

  context "when the user has multiple roles (School and AB)" do
    before do
      sign_in_as_school_induction_tutor(school:, appropriate_body:)
    end

    scenario "the school home page is the default" do
      given_i_browse_to_the_app_root
      i_am_redirected_to_the_school_home_page
      then_i_should_see_school_content
    end

    scenario "the user can switch roles repeatedly" do
      given_i_browse_to_the_app_root
      and_i_switch_to_appropriate_body_role
      i_am_redirected_to_the_appropriate_body_home_page
      then_i_should_see_appropriate_body_content
      and_i_switch_to_school_role
      i_am_redirected_to_the_school_home_page
      then_i_should_see_school_content
    end

    scenario "viewing pages for the inactive role redirects to the active role home page" do
      given_i_browse_to_the_app_root
      i_am_redirected_to_the_school_home_page

      given_i_browse_to_the_appropriate_body_home_page
      i_am_redirected_to_the_school_home_page
      then_i_should_see_school_content
      and_i_switch_to_appropriate_body_role
      i_am_redirected_to_the_appropriate_body_home_page

      given_i_browse_to_the_school_home_page
      i_am_redirected_to_the_appropriate_body_home_page
      then_i_should_see_appropriate_body_content
    end
  end

private

  def given_i_browse_to_the_app_root
    page.goto(root_path)
  end

  def given_i_browse_to_the_appropriate_body_home_page
    page.goto(ab_teachers_path)
  end

  def given_i_browse_to_the_school_home_page
    page.goto(schools_ects_home_path)
  end

  def and_i_switch_to_appropriate_body_role
    page.get_by_role("link", name: "#{school.name} (school)").click
  end

  def and_i_switch_to_school_role
    page.get_by_role("link", name: "#{appropriate_body.name} (appropriate body)").click
  end

  def i_am_redirected_to_the_appropriate_body_home_page
    expect(page).to have_path("/appropriate-body/teachers")
  end

  def i_am_redirected_to_the_school_home_page
    expect(page).to have_path("/school/home/ects")
  end

  def then_i_should_see_school_content
    expect(page.content).to include("Early career teachers (ECT)")
    expect(page.content).to include("Register an ECT starting at your school")
  end

  def then_i_should_see_appropriate_body_content
    expect(page.content).to include("Find and claim a new ECT")
    expect(page.content).to include("Upload a CSV")
  end
end
