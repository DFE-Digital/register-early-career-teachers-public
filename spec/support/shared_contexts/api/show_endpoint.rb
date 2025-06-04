shared_examples "a show endpoint" do
  it "returns the correct resource in a serialized format" do
    authenticated_api_get(path)

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to eql("application/json; charset=utf-8")
    expect(response.body).to eq(serializer.render(resource, root: "data"))
  end

  context "when the resource does not exist" do
    let(:path_id) { SecureRandom.uuid }

    it "returns 404 not found" do
      authenticated_api_get(path)

      expect(response).to have_http_status(:not_found)
      expect(response.content_type).to eql("application/json; charset=utf-8")
      expect(response.body).to eq({ errors: [{ title: "Resource not found", detail: "Nothing could be found for the provided details" }] }.to_json)
    end
  end

  context "when the resource exists but does not belong to the lead provider" do
    let(:resource) do
      lead_provider = FactoryBot.create(:lead_provider, name: "Other Lead Provider")
      registration_period = active_lead_provider.registration_period
      create_resource(active_lead_provider: FactoryBot.create(:active_lead_provider, lead_provider:, registration_period:))
    end

    it "returns 404 not found" do
      authenticated_api_get(path)

      expect(response).to have_http_status(:not_found)
      expect(response.content_type).to eql("application/json; charset=utf-8")
      expect(response.body).to eq({ errors: [{ title: "Resource not found", detail: "Nothing could be found for the provided details" }] }.to_json)
    end
  end
end
