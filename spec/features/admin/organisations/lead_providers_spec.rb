RSpec.describe "Admin organisations lead providers" do
  include UserHelper

  scenario "lead providers page" do
    given_i_am_logged_in_as_an_admin
    and_lead_providers_exist

    when_i_click_organisations_on_the_top_menu
    then_i_should_see_the_admin_organisations_page

    when_i_click_lead_providers_link
    then_i_should_see_the_admin_lead_providers_page
    and_i_should_see_lead_providers
  end

  def given_i_am_logged_in_as_an_admin
    sign_in_as_dfe_user(role: :admin)
  end

  def and_lead_providers_exist
    @lead_providers = FactoryBot.create_list(:lead_provider, 4)
  end

  def when_i_click_organisations_on_the_top_menu
    page.locator('section.govuk-service-navigation').get_by_role('link', name: 'Organisations').click
  end

  def then_i_should_see_the_admin_organisations_page
    expect(page.get_by_role("heading", name: "Organisations")).to be_visible
  end

  def when_i_click_lead_providers_link
    page.locator('main.govuk-main-wrapper').get_by_role('link', name: 'Lead providers').click
  end

  def then_i_should_see_the_admin_lead_providers_page
    expect(page.get_by_role("heading", name: "Lead providers")).to be_visible
  end

  def and_i_should_see_lead_providers
    table = page.locator('main.govuk-main-wrapper table.govuk-table')
    @lead_providers.each do |lp|
      expect(table.get_by_role("link", name: lp.name)).to be_visible
    end
  end
end
