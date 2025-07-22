shared_examples "an index endpoint" do
  context "when 2 resources exist for the lead provider" do
    let!(:resources) do
      [
        create_resource(active_lead_provider:),
        create_resource(active_lead_provider:)
      ]
    end

    it "returns the correct resources in a serialized format" do
      params = {}
      params.deep_merge!(mandatory_params) if defined?(mandatory_params)

      authenticated_api_get(path, params:)

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eql("application/json; charset=utf-8")
      expect(response.body).to eq(serializer.render(apply_expected_order(resources), root: "data"))
    end
  end

  context "when no resources exist for the lead provider" do
    it "returns an empty result in serialized format" do
      params = {}
      params.deep_merge!(mandatory_params) if defined?(mandatory_params)

      authenticated_api_get(path, params:)

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eql("application/json; charset=utf-8")
      expect(response.body).to eq(serializer.render([], root: "data"))
    end
  end
end
