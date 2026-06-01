RSpec.describe "Admin organisations delivery partners" do
  include UserHelper

  scenario "delivery partners page" do
    given_i_am_logged_in_as_an_admin
    and_delivery_partners_exist

    when_i_click_organisations_on_the_top_menu
    then_i_should_see_the_admin_organisations_page

    when_i_click_delivery_partners_link
    then_i_should_see_the_admin_delivery_partners_page
    and_i_should_see_delivery_partners
    and_i_should_see_the_add_a_new_delivery_partner_button

    when_i_search_for_delivery_partner
    then_i_should_see_the_searched_delivery_partner
  end

  scenario "adding a new delivery partner" do
    given_i_am_logged_in_as_an_admin

    when_i_click_organisations_on_the_top_menu
    when_i_click_delivery_partners_link
    when_i_click_add_a_new_delivery_partner

    then_i_should_see_the_add_delivery_partner_form

    when_i_submit_the_form_with_blank_name
    then_i_should_see_a_form_error
    and_i_should_see_the_error_message("Enter a delivery partner name")

    when_i_enter_a_name("Ambition Institute New")
    then_i_should_be_on_the_show_page_for("Ambition Institute New")
    and_i_should_see_a_success_banner("Delivery partner added")
    and_i_should_see_the_api_id
  end

  scenario "adding a delivery partner with a duplicate name" do
    given_i_am_logged_in_as_an_admin
    and_a_delivery_partner_exists_with_name("Existing Partner")

    when_i_click_organisations_on_the_top_menu
    when_i_click_delivery_partners_link
    when_i_click_add_a_new_delivery_partner

    when_i_enter_a_name("existing partner")
    then_i_should_see_a_form_error
  end

  scenario "returning to delivery partners index does not include empty page params" do
    given_i_am_logged_in_as_an_admin
    and_delivery_partners_exist
    and_a_known_delivery_partner_exists
    and_a_contract_period_exists
    and_an_active_lead_provider_exists

    when_i_click_organisations_on_the_top_menu
    when_i_click_delivery_partners_link
    then_i_should_see_the_admin_delivery_partners_page

    and_i_view_a_delivery_partner
    and_i_add_a_lead_provider_partnership
    and_i_click_the_delivery_partners_breadcrumb

    then_i_should_be_on_the_delivery_partners_index_without_empty_page_params
  end

  def given_i_am_logged_in_as_an_admin
    sign_in_as_dfe_user(role: :admin)
  end

  def and_delivery_partners_exist
    @delivery_partners = FactoryBot.create_list(:delivery_partner, 4)
    @searchable_delivery_partner = FactoryBot.create(:delivery_partner, name: "XXX123")
  end

  def and_a_delivery_partner_exists_with_name(name)
    FactoryBot.create(:delivery_partner, name:)
  end

  def and_a_known_delivery_partner_exists
    @known_delivery_partner = FactoryBot.create(:delivery_partner, name: "Known Delivery Partner")
  end

  def and_a_contract_period_exists
    @contract_period = FactoryBot.create(:contract_period, :current)
  end

  def and_an_active_lead_provider_exists
    @lead_provider = FactoryBot.create(:lead_provider)
    FactoryBot.create(:active_lead_provider, lead_provider: @lead_provider, contract_period: @contract_period)
  end

  def when_i_click_organisations_on_the_top_menu
    page.locator("section.govuk-service-navigation").get_by_role("link", name: "Organisations").click
  end

  def then_i_should_see_the_admin_organisations_page
    expect(page.get_by_role("heading", name: "Organisations")).to be_visible
  end

  def when_i_click_delivery_partners_link
    page.locator("main.govuk-main-wrapper").get_by_role("link", name: "Delivery partners").click
  end

  def then_i_should_see_the_admin_delivery_partners_page
    expect(page.get_by_role("heading", name: "Delivery partners")).to be_visible
  end

  def and_i_should_see_delivery_partners
    table = page.locator("main.govuk-main-wrapper table.govuk-table")
    @delivery_partners.each do |lp|
      expect(table.get_by_text(lp.name)).to be_visible
    end
  end

  def and_i_should_see_the_add_a_new_delivery_partner_button
    expect(page.get_by_text("Add a new delivery partner")).to be_visible
  end

  def when_i_search_for_delivery_partner
    page.get_by_label("Search for delivery partner", exact: true).fill(@searchable_delivery_partner.name)
    page.get_by_role("button", name: "Search").click
  end

  def then_i_should_see_the_searched_delivery_partner
    table = page.locator("main.govuk-main-wrapper table.govuk-table")
    expect(table.get_by_text(@searchable_delivery_partner.name)).to be_visible
    @delivery_partners.each do |lp|
      expect(table.get_by_text(lp.name)).not_to be_visible
    end
  end

  def when_i_click_add_a_new_delivery_partner
    page.get_by_text("Add a new delivery partner").click
  end

  def then_i_should_see_the_add_delivery_partner_form
    expect(page.get_by_role("heading", name: "Delivery partner name")).to be_visible
    expect(page.get_by_label("Delivery partner name")).to be_visible
  end

  def when_i_submit_the_form_with_blank_name
    page.get_by_label("Delivery partner name").fill("")
    page.get_by_role("button", name: "Confirm").click
  end

  def when_i_enter_a_name(name)
    page.get_by_label("Delivery partner name").fill(name)
    page.get_by_role("button", name: "Confirm").click
  end

  def and_i_should_see_the_error_message(message)
    expect(page.locator(".govuk-error-summary").get_by_text(message, exact: false)).to be_visible
  end

  def then_i_should_be_on_the_show_page_for(name)
    expect(page.get_by_role("heading", name:)).to be_visible
  end

  def and_i_should_see_a_success_banner(text)
    expect(page.get_by_text(text, exact: false)).to be_visible
  end

  def and_i_should_see_the_api_id
    expect(page.get_by_text("API ID:", exact: false)).to be_visible
  end

  def then_i_should_see_a_form_error
    expect(page.locator(".govuk-error-summary")).to be_visible
  end

  def and_i_view_a_delivery_partner
    page.get_by_role("link", name: @known_delivery_partner.name).click
  end

  def and_i_add_a_lead_provider_partnership
    page.get_by_role("link", name: "Add").first.click
    page.get_by_label(@lead_provider.name).check
    page.get_by_role("button", name: "Confirm").click
  end

  def and_i_click_the_delivery_partners_breadcrumb
    page.get_by_role("link", name: "Delivery partners").click
  end

  def then_i_should_be_on_the_delivery_partners_index_without_empty_page_params
    expect(page.url).not_to include("page=")
    expect(page.url).not_to include("q=")
    expect(page.get_by_role("heading", name: "Delivery partners")).to be_visible
  end
end
