RSpec.describe "Admin organisations induction platforms" do
  include UserHelper

  scenario "viewing the appropriate bodies that authorised a platform" do
    given_i_am_logged_in_as_an_admin
    and_an_induction_platform_has_been_authorised

    when_i_click_organisations_on_the_top_menu
    and_i_click_the_induction_platforms_link
    then_i_should_see_the_induction_platforms_page

    when_i_click_the_induction_platform
    then_i_should_see_who_authorised_the_platform

    when_i_click_the_appropriate_body
    then_i_should_see_the_appropriate_body_page
  end

  def given_i_am_logged_in_as_an_admin
    sign_in_as_dfe_user(role: :admin)
  end

  def and_an_induction_platform_has_been_authorised
    @appropriate_body_period = FactoryBot.create(:appropriate_body_period, name: "Burns Slant Drilling Co.")
    FactoryBot.create(:api_oauth_authorization, :with_token,
                      client: FactoryBot.create(:api_oauth_client, name: "Alpha Induction Platform"),
                      appropriate_body_period: @appropriate_body_period,
                      granted_by_name: "Sarah Jones",
                      created_at: Time.zone.local(2026, 8, 13, 12))
  end

  def when_i_click_organisations_on_the_top_menu
    page.locator("section.govuk-service-navigation").get_by_role("link", name: "Organisations").click
  end

  def and_i_click_the_induction_platforms_link
    page.locator("main.govuk-main-wrapper").get_by_role("link", name: "Induction platforms").click
  end

  def then_i_should_see_the_induction_platforms_page
    expect(page.get_by_role("heading", name: "Induction platforms")).to be_visible
  end

  def when_i_click_the_induction_platform
    page.locator("main.govuk-main-wrapper").get_by_role("link", name: "Alpha Induction Platform").click
  end

  def then_i_should_see_who_authorised_the_platform
    expect(page.get_by_role("heading", name: "Alpha Induction Platform")).to be_visible

    table = page.locator("main.govuk-main-wrapper table.govuk-table")
    expect(table.get_by_text("Sarah Jones")).to be_visible
    expect(table.get_by_text("13 August 2026")).to be_visible
  end

  def when_i_click_the_appropriate_body
    page.locator("main.govuk-main-wrapper").get_by_role("link", name: "Burns Slant Drilling Co.").click
  end

  def then_i_should_see_the_appropriate_body_page
    expect(page.get_by_role("heading", name: "Burns Slant Drilling Co.")).to be_visible
  end
end
