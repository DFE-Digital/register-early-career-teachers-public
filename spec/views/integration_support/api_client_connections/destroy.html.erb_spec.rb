RSpec.describe "integration_support/api_client_connections/destroy.html.erb" do
  it "shows an empty response body in a green card" do
    assign(:response, Faraday::Response.new(status: 200, body: ""))

    render

    expect(rendered).to have_css(".app-summary-card--green", text: "HTTP 200 OK")
    expect(rendered).to have_css(".app-summary-card--green", text: "Empty response body")
  end
end
