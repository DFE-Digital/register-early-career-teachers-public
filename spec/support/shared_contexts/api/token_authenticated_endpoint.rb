shared_examples "a token authenticated endpoint" do |request_method|
  it "returns unauthorized when no token is provided" do
    send(request_method, path)
    expect(response).to have_http_status(:unauthorized)
  end

  it "returns unauthorized when an invalid token is provided" do
    send("authenticated_api_#{request_method}", path, token: "invalid")
    expect(response).to have_http_status(:unauthorized)
  end

  it "does not return unauthorized when a valid token is provided" do
    send("authenticated_api_#{request_method}", path)
    expect(response).not_to have_http_status(:unauthorized)
  end
end
