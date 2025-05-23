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
    # expect(parsed_response_errors.size).to eq(1)
    # expect(parsed_response_errors.first["title"]).to eql("Bad request")
    # expect(parsed_response_errors.first["detail"]).to eql("The '#/page[page]' and '#/page[per_page]' parameter values must be a valid positive number")
  end
end
