RSpec.describe "Admin: Managing delivery partner lead providers", type: :feature do
  scenario "User can add first lead provider to delivery partner" do
    given_i_am_logged_in_as_an_admin
    and_delivery_partner_and_lead_providers_exist

    when_i_visit_the_delivery_partner_page
    then_i_should_see_no_partnerships_message

    when_i_navigate_to_add_lead_providers_page
    then_i_should_see_the_add_lead_providers_form
    and_i_should_see_all_available_lead_providers

    when_i_select_a_lead_provider_and_submit
    then_i_should_see_success_message
    and_i_should_see_the_new_partnership
    and_the_partnership_should_exist_in_database
  end

  scenario "User can add multiple lead providers at once" do
    given_i_am_logged_in_as_an_admin
    and_delivery_partner_and_lead_providers_exist

    when_i_navigate_to_add_lead_providers_page
    when_i_select_multiple_lead_providers_and_submit
    then_i_should_see_success_message
    and_i_should_see_multiple_partnerships
  end

  scenario "User sees error when no lead providers selected" do
    given_i_am_logged_in_as_an_admin
    and_delivery_partner_and_lead_providers_exist

    when_i_navigate_to_add_lead_providers_page
    when_i_submit_without_selecting_providers
    then_i_should_see_validation_error
  end

  scenario "User can add lead providers when some already exist" do
    given_i_am_logged_in_as_an_admin
    and_delivery_partner_and_lead_providers_exist
    and_an_existing_partnership_exists

    when_i_visit_the_delivery_partner_page
    then_i_should_see_existing_partnership
    and_i_should_see_change_link

    when_i_click_change_link
    then_i_should_see_existing_partnerships_listed
    and_i_should_only_see_unassigned_providers_as_checkboxes

    when_i_add_another_lead_provider
    then_i_should_see_success_message
    and_i_should_see_both_partnerships
  end

private

  def given_i_am_logged_in_as_an_admin
    sign_in_as_dfe_user(role: :admin)
  end

  def and_delivery_partner_and_lead_providers_exist
    @delivery_partner = FactoryBot.create(:delivery_partner, name: "Test Delivery Partner")
    @contract_period = FactoryBot.create(:contract_period, year: 2025)

    @lead_provider_1 = FactoryBot.create(:lead_provider, name: "Lead Provider One")
    @lead_provider_2 = FactoryBot.create(:lead_provider, name: "Lead Provider Two")
    @lead_provider_3 = FactoryBot.create(:lead_provider, name: "Lead Provider Three")

    @active_lead_provider_1 = FactoryBot.create(:active_lead_provider, lead_provider: @lead_provider_1, contract_period: @contract_period)
    @active_lead_provider_2 = FactoryBot.create(:active_lead_provider, lead_provider: @lead_provider_2, contract_period: @contract_period)
    @active_lead_provider_3 = FactoryBot.create(:active_lead_provider, lead_provider: @lead_provider_3, contract_period: @contract_period)
  end

  def and_an_existing_partnership_exists
    @existing_partnership = FactoryBot.create(
      :lead_provider_delivery_partnership,
      delivery_partner: @delivery_partner,
      active_lead_provider: @active_lead_provider_1
    )
  end

  def when_i_visit_the_delivery_partner_page
    page.goto("/admin/organisations/delivery-partners/#{@delivery_partner.id}")
  end

  def then_i_should_see_no_partnerships_message
    expect(page.get_by_text("No lead provider partnerships found")).to be_visible
  end

  def then_i_should_see_existing_partnership
    expect(page.get_by_text("Lead Provider One")).to be_visible
  end

  def and_i_should_see_change_link
    expect(page.get_by_role("link", name: "Change")).to be_visible
  end

  def when_i_navigate_to_add_lead_providers_page
    page.goto("/admin/organisations/delivery-partners/#{@delivery_partner.id}/edit?year=#{@contract_period.year}")
  end

  def when_i_click_change_link
    page.get_by_role("link", name: "Change").click
  end

  def then_i_should_see_the_add_lead_providers_form
    expect(page.get_by_text("Add new lead providers")).to be_visible
    expect(page.get_by_text("Select additional lead providers that should work with Test Delivery Partner in 2025")).to be_visible
  end

  def and_i_should_see_all_available_lead_providers
    expect(page.get_by_label("Lead Provider One")).to be_visible
    expect(page.get_by_label("Lead Provider Two")).to be_visible
    expect(page.get_by_label("Lead Provider Three")).to be_visible
  end

  def then_i_should_see_existing_partnerships_listed
    expect(page.get_by_text("Currently working with:")).to be_visible
    expect(page.get_by_text("Lead Provider One")).to be_visible
  end

  def and_i_should_only_see_unassigned_providers_as_checkboxes
    # Lead Provider One should not be a checkbox since it's already assigned
    expect(page.get_by_label("Lead Provider One")).not_to be_visible
    expect(page.get_by_label("Lead Provider Two")).to be_visible
    expect(page.get_by_label("Lead Provider Three")).to be_visible
  end

  def when_i_select_a_lead_provider_and_submit
    page.get_by_label("Lead Provider One").check
    page.get_by_role("button", name: "Confirm").click
  end

  def when_i_select_multiple_lead_providers_and_submit
    page.get_by_label("Lead Provider One").check
    page.get_by_label("Lead Provider Two").check
    page.get_by_role("button", name: "Confirm").click
  end

  def when_i_add_another_lead_provider
    page.get_by_label("Lead Provider Two").check
    page.get_by_role("button", name: "Confirm").click
  end

  def when_i_submit_without_selecting_providers
    page.get_by_role("button", name: "Confirm").click
  end

  def then_i_should_see_success_message
    expect(page.get_by_text("Lead provider partners updated")).to be_visible
  end

  def then_i_should_see_validation_error
    expect(page.get_by_text("Select at least one lead provider")).to be_visible
  end

  def and_i_should_see_the_new_partnership
    expect(page.get_by_text("Lead Provider One")).to be_visible
  end

  def and_i_should_see_multiple_partnerships
    expect(page.get_by_text("Lead Provider One")).to be_visible
    expect(page.get_by_text("Lead Provider Two")).to be_visible
  end

  def and_i_should_see_both_partnerships
    expect(page.get_by_text("Lead Provider One")).to be_visible
    expect(page.get_by_text("Lead Provider Two")).to be_visible
  end

  def and_the_partnership_should_exist_in_database
    expect(@delivery_partner.lead_provider_delivery_partnerships.count).to eq(1)
    expect(@delivery_partner.lead_provider_delivery_partnerships.first.lead_provider).to eq(@lead_provider_1)
  end
end
