RSpec.describe "Access denial" do
  context "when the user has not completed onboarding with DfE Sign In" do
    # DSI response includes neither UUID and URN
    before do
      sign_in_as_unrecognised_user(organisation_id: nil, organisation_urn: nil)
    end

    scenario "they see the access denied page" do
      then_i_see_the_access_denied_page

      and_i_see_the_title(
        "You cannot use this service until you have DfE Sign-in account access to a school or organisation"
      )

      expect(page.content).to include(
        "Your DfE Sign-in account does not have access to a school or organisation."
      )

      expect(page.content).to include(
        "You cannot use this service until you have access."
      )

      expect(page.content).not_to include("Invalid Organisation")

      and_i_see_a_link_to_request_access_to_a_school_or_organisation
    end
  end

  context "when the user is from an unrecognised organisation" do
    # DSI response only includes unrecognised UUID
    before do
      sign_in_as_unrecognised_user(organisation_urn: nil)
    end

    scenario "they see the access denied page" do
      then_i_see_the_access_denied_page

      and_i_see_the_title(
        "You do not have approved access to this service from your school or organisation"
      )

      and_i_see_my_organisation_name
      and_i_see_a_link_to_request_access_to_the_service
    end
  end

  context "when the user is from an unrecognised school" do
    # DSI response includes both unrecognised UUID and URN
    before do
      sign_in_as_unrecognised_user
    end

    scenario "they see the access denied page" do
      then_i_see_the_access_denied_page

      and_i_see_the_title(
        "You do not have approved access to this service from your school or organisation"
      )

      and_i_see_my_organisation_name
      and_i_see_a_link_to_request_access_to_the_service
    end
  end

  context "when the user is from a valid school which was formerly an AB" do
    let(:school) { FactoryBot.create(:school) }

    # DSI response includes a valid URN
    before do
      sign_in_as_unrecognised_user(organisation_urn: school.urn)
    end

    scenario "they see the access denied page" do
      then_i_see_the_access_denied_page

      and_i_see_the_title(
        "You do not have approved access to this service from your school or organisation"
      )

      and_i_see_my_organisation_name
      and_i_see_a_link_to_request_access_to_the_service
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
    expect(page.content).to include(
      "Request access to a school or organisation using your DfE Sign-in account"
    )

    expect(page.content).to include(
      "https://services.signin.education.gov.uk/request-organisation/search"
    )
  end

  def and_i_see_my_organisation_name
    expect(page.content).to include(
      "You’ve tried to access the ‘Register early career teachers’ service with Invalid Organisation as your school or organisation."
    )

    expect(page.content).to include(
      "You do not have approved access to the service from Invalid Organisation."
    )
  end

  def and_i_see_a_link_to_request_access_to_the_service
    expect(page.content).to include(
      "Request access to the service using your DfE Sign-in account"
    )

    expect(page.content).to include(
      "https://services.signin.education.gov.uk/my-services"
    )
  end
end
