RSpec.describe "Access denial" do
  context "when the user has not completed onboarding with DfE Sign In" do
    # DSI response includes neither UUID and URN
    before do
      sign_in_as_unrecognised_user(
        organisation_id: nil,
        organisation_urn: nil,
        organisation_name: "Not-yet-onboarded Org"
      )
    end

    scenario "they see the access denied page" do
      then_i_see_the_access_denied_page

      and_i_see_the_title(
        "You cannot use this service until you have DfE Sign-in account access to a school or organisation"
      )

      paragraph1 = page.locator("p", hasText: "Your DfE Sign-in account does not have access to a school or organisation.")
      expect(paragraph1).to be_visible
      paragraph2 = page.locator("p", hasText: "You cannot use this service until you have access.")
      expect(paragraph2).to be_visible

      expect(page.locator("body")).not_to have_text("Not-yet-onboarded Org")

      and_i_see_a_link_to_request_access_to_a_school_or_organisation
    end
  end

  context "when the user is from an unrecognised organisation" do
    let!(:appropriate_body_period) do
      FactoryBot.create(:appropriate_body_period, :with_dsi)
    end

    # DSI response only includes unrecognised UUID
    before do
      sign_in_as_unrecognised_user(
        organisation_id: appropriate_body_period.dfe_sign_in_organisation.uuid,
        organisation_urn: nil,
        organisation_name: "Unrecognised Org"
      )
    end

    scenario "they see the access denied page" do
      then_i_see_the_access_denied_page

      and_i_see_the_title(
        "You do not have approved access to this service from your school or organisation"
      )

      and_i_see_my_organisation_name("Unrecognised Org")
      and_i_click_a_button_to_request_access_to_the_service
      and_an_access_request_is_sent
    end
  end

  context "when the user is from an unrecognised school" do
    let!(:school) { FactoryBot.create(:school) }

    # DSI response includes both unrecognised UUID and URN
    before do
      sign_in_as_unrecognised_user(
        organisation_urn: school.urn,
        organisation_name: "Unrecognised School"
      )
    end

    scenario "they see the access denied page" do
      then_i_see_the_access_denied_page

      and_i_see_the_title(
        "You do not have approved access to this service from your school or organisation"
      )

      and_i_see_my_organisation_name("Unrecognised School")
      and_i_click_a_button_to_request_access_to_the_service
      and_an_access_request_is_sent
    end
  end

  context "when the user is from a valid school which was formerly an AB" do
    let(:school) { FactoryBot.create(:school, :with_dsi) }

    # DSI response includes a valid URN
    before do
      sign_in_as_unrecognised_user(
        organisation_id: school.dfe_sign_in_organisation.uuid,
        organisation_urn: school.urn,
        organisation_name: "Former-AB School"
      )
    end

    scenario "they see the access denied page" do
      then_i_see_the_access_denied_page

      and_i_see_the_title(
        "You do not have approved access to this service from your school or organisation"
      )

      and_i_see_my_organisation_name("Former-AB School")
      and_i_click_a_button_to_request_access_to_the_service
      and_an_access_request_is_sent
    end
  end

private

  def then_i_see_the_access_denied_page
    expect(page).to have_path("/access-denied")
  end

  def and_i_see_the_title(title)
    expect(page.title).to start_with(title)
  end

  def and_i_see_a_link_to_request_access_to_a_school_or_organisation
    link = page.get_by_role(
      "link",
      name: "Request access to a school or organisation using your DfE Sign-in account"
    )
    expect(link).to be_visible
    expect(link).to have_attribute(
      "href",
      Rails.application.config.dfe_sign_in_request_organisation_url
    )
  end

  def and_i_see_my_organisation_name(name)
    paragraph1 = page.locator("p", hasText: "You’ve tried to access the ‘Register early career teachers’ service with #{name} as your school or organisation.")
    expect(paragraph1).to be_visible

    paragraph2 = page.locator("p", hasText: "You do not have approved access to the service from #{name}.")
    expect(paragraph2).to be_visible
  end

  def and_i_click_a_button_to_request_access_to_the_service
    page.get_by_role("button", name: "Request access to the service").click
  end

  def and_an_access_request_is_sent
    expect(DfESignIn::AccessRequestJob).to have_been_enqueued.once
    expect(page.get_by_role("heading", name: "Request sent")).to be_visible
  end
end
