RSpec.describe "integration_support/api_client_connections/update.html.erb" do
  it "shows a successful response in a green card with the formatted body" do
    assign(:response, Faraday::Response.new(status: 201, body: { access_token: "abc" }))

    render

    expect(rendered).to have_css(".app-summary-card--green", text: "HTTP 201 Created")
    expect(rendered).to have_css(".app-summary-card--green pre", text: '"access_token": "abc"')
  end

  it "shows any other response in a red card with the raw body" do
    assign(:response, Faraday::Response.new(status: 404, body: "<html><body>Not found</body></html>"))

    render

    expect(rendered).to have_css(".app-summary-card--red", text: "HTTP 404 Not Found")
    expect(rendered).to have_css(".app-summary-card--red .govuk-details", text: "Raw response body")
  end
end
