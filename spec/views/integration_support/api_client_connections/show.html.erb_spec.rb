RSpec.describe "integration_support/api_client_connections/show.html.erb" do
  it "shows a returned code in a green card, warns about a state mismatch and offers the token exchange" do
    assign(:api_client_connection, IntegrationSupport::APIClientConnection.new(state: "state-123", code: "the-code", returned_state: "tampered-state"))

    render

    expect(rendered).to have_css(".app-summary-card--green", text: "the-code")
    expect(rendered).to have_css(".app-summary-card--green", text: "does not match the state sent with the authorization request")
    expect(rendered).to have_button("Exchange code for token")
  end

  it "shows a returned error in a red card instead of the form" do
    assign(:api_client_connection, IntegrationSupport::APIClientConnection.new(error: "access_denied", error_description: "User refused connection"))

    render

    expect(rendered).to have_css(".app-summary-card--red", text: "User refused connection")
    expect(rendered).to have_no_button("Exchange code for token")
  end
end
