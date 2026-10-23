RSpec.describe "Integration support API client connection" do
  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period, name: "Golden Leaf Teaching School Hub") }
  let(:other_appropriate_body_period) { FactoryBot.create(:appropriate_body_period, name: "Another Teaching School Hub") }

  before do
    allow(Rails.application.config).to receive(:enable_api_test_client).and_return(true)

    given_i_am_signed_in_as_an_admin
    when_i_create_a_test_client
    then_i_am_asked_to_sign_in_as_an_appropriate_body_user
  end

  scenario "authorising a client, obtaining and revoking an access token" do
    when_i_start_a_connection_for(appropriate_body_period)
    then_my_client_is_preselected

    when_i_start_the_authorisation_request
    then_i_am_asked_to_authorise_the_client

    when_i_authorise_the_client
    then_i_am_redirected_back_with_a_code

    when_i_exchange_the_code_for_an_access_token
    then_i_receive_an_access_token

    when_i_revoke_the_access_token
    then_the_access_token_is_revoked
  end

  scenario "authorising a different appropriate body is denied" do
    when_i_start_a_connection_for(other_appropriate_body_period)
    then_my_client_is_preselected

    when_i_start_the_authorisation_request
    then_i_am_redirected_back_with_an_error
  end

private

  def given_i_am_signed_in_as_an_admin
    sign_in_as_dfe_user(role: :admin)
  end

  def when_i_create_a_test_client
    page.goto("/integration-support/api-clients/new")
    page.get_by_label("Name").fill("Test Client")
    page.get_by_role("button", name: "Create client").click
  end

  def then_i_am_asked_to_sign_in_as_an_appropriate_body_user
    expect(page.locator("body")).to have_text("You must be signed in as an appropriate body user to start an authorization request.")
  end

  def when_i_start_a_connection_for(appropriate_body)
    sign_in_as_appropriate_body_user(appropriate_body: appropriate_body_period)

    page.goto("/integration-support/api-client-connection/new")
    page.get_by_label("Appropriate body period UUID").select_option(label: appropriate_body.name)
  end

  def then_my_client_is_preselected
    expect(page.locator("select[name='integration_support_api_client_connection[client_id]'] option:checked")).to have_text("Test Client")
  end

  def when_i_start_the_authorisation_request
    page.get_by_role("button", name: "Start authorization request").click
  end

  def then_i_am_asked_to_authorise_the_client
    expect(page.locator("body")).to have_text(
      "Test Client has asked for access to early career teacher (ECT) data for Golden Leaf Teaching School Hub."
    )
  end

  def when_i_authorise_the_client
    page.get_by_role("button", name: "Authorise").click
  end

  def then_i_am_redirected_back_with_a_code
    expect(page).to have_path("/integration-support/api-client-connection")
    expect(page.locator("body")).to have_text("Successfully redirected")
    expect(page.locator("body")).to have_text("code")
    expect(page.locator("body")).to have_text("state")
  end

  def then_i_am_redirected_back_with_an_error
    expect(page.locator("body")).to have_text("Redirected with errors")
    expect(page.locator("body")).to have_text("access_denied")
  end

  def when_i_exchange_the_code_for_an_access_token
    page.get_by_role("button", name: "Exchange code for token").click
  end

  def then_i_receive_an_access_token
    expect(page.locator("pre")).to have_text("access_token")
  end

  def when_i_revoke_the_access_token
    page.get_by_role("link", name: "Revoke access token").click
    page.get_by_role("button", name: "Revoke token").click
  end

  def then_the_access_token_is_revoked
    expect(page.locator("body")).to have_text("Revoke access token")
    expect(page.locator("body")).to have_text("Empty response body")
  end
end
