shared_examples "a paginated endpoint" do
  before do
    8.times { create_resource(active_lead_provider:) }
  end

  it "returns 5 resources on page 1" do
    authenticated_api_get(path, params: { page: { per_page: 5, page: 1 } })

    expect(response).to have_http_status(:success)
    expect(parsed_response_data.size).to eq(5)
  end

  it "returns 3 resources on page 2" do
    authenticated_api_get(path, params: { page: { per_page: 5, page: 2 } })

    expect(response).to have_http_status(:success)
    expect(parsed_response_data.size).to eq(3)
  end

  it "returns empty for page 3" do
    authenticated_api_get(path, params: { page: { per_page: 5, page: 3 } })

    expect(response).to have_http_status(:success)
    expect(parsed_response_data).to be_empty
  end

  it "returns error when requesting page -1" do
    authenticated_api_get(path, params: { page: { per_page: 5, page: -1 } })

    expect(response).to have_http_status(:bad_request)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq({ errors: [{ title: "Bad request", detail: "The '#/page[page]' and '#/page[per_page]' parameter values must be a valid positive number" }] }.to_json)
  end
end
