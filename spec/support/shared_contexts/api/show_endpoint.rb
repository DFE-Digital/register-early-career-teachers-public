shared_examples "a show endpoint" do
  it "returns the correct resource in a serialized format" do
    params = {}
    params.merge!(mandatory_params) if defined?(mandatory_params)

    authenticated_api_get(path, params:)

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq(serializer.render(resource, root: "data"))
  end

  context "when the resource does not exist" do
    let(:path_id) { SecureRandom.uuid }

    it "returns 404 not found" do
      params = {}
      params.merge!(mandatory_params) if defined?(mandatory_params)
      authenticated_api_get(path, params:)

      expect(response).to have_http_status(:not_found)
      expect(response.content_type).to eql("application/json; charset=utf-8")
      expect(response.body).to eq({ errors: [{ title: "Resource not found", detail: "Nothing could be found for the provided details" }] }.to_json)
    end
  end
end
